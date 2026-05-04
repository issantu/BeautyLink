"""OmniFlix backend — Stripe Checkout for international subscriptions & PPV.

The RDC Mobile Money flow (USSD composer) stays entirely client-side in the
Flutter app; this backend only exists for Stripe (card / international).
"""
from __future__ import annotations

import os
import uuid
from datetime import datetime, timezone
from typing import Optional

from dotenv import load_dotenv
from fastapi import FastAPI, HTTPException, Request, Response
from fastapi.middleware.cors import CORSMiddleware
from motor.motor_asyncio import AsyncIOMotorClient
from pydantic import BaseModel, Field

from emergentintegrations.payments.stripe.checkout import (
    StripeCheckout,
    CheckoutSessionRequest,
)

load_dotenv()

MONGO_URL = os.environ.get("MONGO_URL")
DB_NAME = os.environ.get("DB_NAME")
STRIPE_API_KEY = os.environ.get("STRIPE_API_KEY")

# ── Fixed, server-defined packages (never trust the frontend for amount) ────
# Prices are in USD.
PACKAGES: dict[str, dict] = {
    "daily_sub":   {"amount": 1.99,  "label": "Pass Journée",       "plan": "daily"},
    "monthly_sub": {"amount": 14.99, "label": "Abonnement Mensuel", "plan": "monthly"},
}

# PPV events: fixed mapping of event_id → USD price.
# Mirrors lib/models/event.dart > SampleEvents.events (priceFc / 2850 rate).
PPV_PRICES: dict[str, float] = {
    "evt_001": 0.70,   # FINALE LINAFOOT 2025  (2000 FC)
    "evt_002": 1.05,   # GALA DE BOXE          (3000 FC)
    "evt_003": 1.75,   # CONCERT FALLY IPUPA   (5000 FC)
    "evt_004": 1.40,   # MMA AFRICA            (4000 FC)
    "evt_005": 0.00,   # MESSE DE NOEL (gratuit)
    "evt_006": 0.53,   # LUTTE TRADITIONNELLE  (1500 FC)
}

app = FastAPI(title="OmniFlix API", version="1.0.0")

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

mongo_client = AsyncIOMotorClient(MONGO_URL)
db = mongo_client[DB_NAME]
tx_col = db.payment_transactions


# ── Models ──────────────────────────────────────────────────────────────────

class CheckoutRequestBody(BaseModel):
    package_id: Optional[str] = Field(None, description="daily_sub | monthly_sub")
    ppv_event_id: Optional[str] = Field(None, description="PPV event id (evt_*)")
    origin_url: str = Field(..., description="Frontend origin for success/cancel URLs")


class CheckoutResponse(BaseModel):
    session_id: str
    url: str
    amount: float
    currency: str = "usd"


class StatusResponse(BaseModel):
    session_id: str
    status: str
    payment_status: str
    amount_total: int
    currency: str
    already_processed: bool = False


# ── Helpers ─────────────────────────────────────────────────────────────────

def _stripe(origin_url: str) -> StripeCheckout:
    webhook_url = f"{origin_url.rstrip('/')}/api/webhook/stripe"
    return StripeCheckout(api_key=STRIPE_API_KEY, webhook_url=webhook_url)


# ── Routes ──────────────────────────────────────────────────────────────────

@app.get("/api/health")
async def health():
    return {"ok": True, "service": "omniflix-api"}


@app.get("/api/stripe/packages")
async def get_packages():
    """Expose the available USD packages to the Flutter app (display only)."""
    return {"packages": PACKAGES, "ppv_prices": PPV_PRICES}


@app.post("/api/stripe/checkout", response_model=CheckoutResponse)
async def create_checkout(body: CheckoutRequestBody):
    # Resolve amount from server-defined mapping only
    if body.package_id:
        pkg = PACKAGES.get(body.package_id)
        if not pkg:
            raise HTTPException(400, "Invalid package_id")
        amount = float(pkg["amount"])
        metadata = {
            "kind": "subscription",
            "plan": pkg["plan"],
            "package_id": body.package_id,
        }
    elif body.ppv_event_id:
        price = PPV_PRICES.get(body.ppv_event_id)
        if price is None:
            raise HTTPException(400, "Invalid ppv_event_id")
        if price <= 0:
            raise HTTPException(400, "This event is free, no payment needed")
        amount = float(price)
        metadata = {"kind": "ppv", "event_id": body.ppv_event_id}
    else:
        raise HTTPException(400, "package_id or ppv_event_id required")

    origin = body.origin_url.rstrip("/")
    success_url = f"{origin}/payment-success.html?session_id={{CHECKOUT_SESSION_ID}}"
    cancel_url = f"{origin}/payment-cancel.html"

    stripe = _stripe(origin)
    session = await stripe.create_checkout_session(
        CheckoutSessionRequest(
            amount=amount,
            currency="usd",
            success_url=success_url,
            cancel_url=cancel_url,
            metadata=metadata,
        )
    )

    await tx_col.insert_one({
        "_id": str(uuid.uuid4()),
        "session_id": session.session_id,
        "amount": amount,
        "currency": "usd",
        "metadata": metadata,
        "payment_status": "initiated",
        "status": "open",
        "created_at": datetime.now(timezone.utc).isoformat(),
        "updated_at": datetime.now(timezone.utc).isoformat(),
    })

    return CheckoutResponse(
        session_id=session.session_id,
        url=session.url,
        amount=amount,
    )


@app.get("/api/stripe/status/{session_id}", response_model=StatusResponse)
async def get_status(session_id: str, request: Request):
    existing = await tx_col.find_one({"session_id": session_id}, {"_id": 0})
    if not existing:
        raise HTTPException(404, "Unknown session_id")

    origin = str(request.base_url).rstrip("/")
    stripe = _stripe(origin)
    status = await stripe.get_checkout_status(session_id)

    already = existing.get("payment_status") == "paid"

    if status.payment_status == "paid" and not already:
        await tx_col.update_one(
            {"session_id": session_id},
            {"$set": {
                "payment_status": "paid",
                "status": status.status,
                "amount_total_cents": status.amount_total,
                "updated_at": datetime.now(timezone.utc).isoformat(),
            }},
        )
    elif status.status == "expired" and not already:
        await tx_col.update_one(
            {"session_id": session_id},
            {"$set": {
                "status": "expired",
                "updated_at": datetime.now(timezone.utc).isoformat(),
            }},
        )

    return StatusResponse(
        session_id=session_id,
        status=status.status,
        payment_status=status.payment_status,
        amount_total=status.amount_total,
        currency=status.currency,
        already_processed=already,
    )


@app.post("/api/webhook/stripe")
async def stripe_webhook(request: Request):
    body = await request.body()
    sig = request.headers.get("Stripe-Signature", "")

    origin = str(request.base_url).rstrip("/")
    stripe = _stripe(origin)
    event = await stripe.handle_webhook(body, sig)

    if event.payment_status == "paid":
        await tx_col.update_one(
            {"session_id": event.session_id},
            {"$set": {
                "payment_status": "paid",
                "status": "complete",
                "webhook_event_id": event.event_id,
                "updated_at": datetime.now(timezone.utc).isoformat(),
            }},
            upsert=False,
        )

    return {"received": True}


# ── Success / Cancel HTML landing pages (opened in external browser) ────────

@app.get("/payment-success.html")
async def payment_success_page():
    return Response(
        content="""<!DOCTYPE html>
<html lang="fr"><head><meta charset="utf-8">
<title>Paiement réussi — OmniFlix</title>
<meta name="viewport" content="width=device-width,initial-scale=1">
<style>
  body{margin:0;min-height:100vh;display:flex;align-items:center;justify-content:center;
       font-family:-apple-system,BlinkMacSystemFont,'Segoe UI',sans-serif;
       background:linear-gradient(135deg,#0A0E1A,#141928);color:#fff;text-align:center}
  .card{padding:40px;max-width:420px}
  .check{width:80px;height:80px;margin:0 auto 20px;border-radius:50%;
         background:linear-gradient(135deg,#00E676,#00BFA5);
         display:flex;align-items:center;justify-content:center;font-size:42px}
  h1{font-size:26px;margin:0 0 10px;font-weight:700}
  p{color:#8899BB;line-height:1.6}
  .hint{margin-top:24px;padding:14px;background:rgba(124,77,255,.1);
        border:1px solid rgba(124,77,255,.3);border-radius:12px;font-size:13px}
</style></head>
<body><div class="card">
  <div class="check">✓</div>
  <h1>Paiement confirmé !</h1>
  <p>Votre paiement Stripe a bien été traité.</p>
  <div class="hint">🎬 Retournez dans l'app <b>OmniFlix</b><br>
  et appuyez sur <b>« J'ai payé — Confirmer »</b> pour activer votre accès.</div>
</div></body></html>""",
        media_type="text/html",
    )


@app.get("/payment-cancel.html")
async def payment_cancel_page():
    return Response(
        content="""<!DOCTYPE html>
<html lang="fr"><head><meta charset="utf-8">
<title>Paiement annulé — OmniFlix</title>
<meta name="viewport" content="width=device-width,initial-scale=1">
<style>
  body{margin:0;min-height:100vh;display:flex;align-items:center;justify-content:center;
       font-family:-apple-system,BlinkMacSystemFont,'Segoe UI',sans-serif;
       background:linear-gradient(135deg,#0A0E1A,#141928);color:#fff;text-align:center}
  .card{padding:40px;max-width:420px}
  .x{width:80px;height:80px;margin:0 auto 20px;border-radius:50%;
     background:rgba(255,107,107,.15);border:2px solid #FF6B6B;
     display:flex;align-items:center;justify-content:center;font-size:42px;color:#FF6B6B}
  h1{font-size:24px;margin:0 0 10px;font-weight:700}
  p{color:#8899BB;line-height:1.6}
</style></head>
<body><div class="card">
  <div class="x">✕</div>
  <h1>Paiement annulé</h1>
  <p>Aucun montant n'a été débité.<br>Vous pouvez réessayer depuis l'app OmniFlix.</p>
</div></body></html>""",
        media_type="text/html",
    )
