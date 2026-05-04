"""Mobile Money RDC — adaptateurs STK Push (Vodacom M-Pesa, Airtel, Orange,
Africell).

Chaque adaptateur expose :
  - async initiate(phone, amount_fc, reference) -> dict
      Déclenche un STK Push. L'utilisateur reçoit une pop-up PIN sur son
      téléphone. Retourne {operator_reference, status: "pending"|"failed", ...}
  - async status(operator_reference) -> dict
      Interroge l'API de l'opérateur. Retourne
      {status: "pending"|"completed"|"failed", raw: {...}}

En `MOBILE_MONEY_MODE=sandbox`, les 4 adaptateurs simulent un STK Push qui se
complète automatiquement 3 secondes après l'initiation (90 % réussite, 10 %
échec pour permettre de tester les deux chemins).

En `MOBILE_MONEY_MODE=live`, les appels réels sont effectués (credentials
requis dans backend/.env). Les TODO marquent les points d'implémentation réelle
à compléter une fois les comptes marchands opérationnels.
"""
from __future__ import annotations

import asyncio
import os
import random
import time
import uuid
from abc import ABC, abstractmethod
from typing import Any

import httpx

MODE = os.environ.get("MOBILE_MONEY_MODE", "sandbox").lower()
IS_SANDBOX = MODE != "live"

# Sandbox state : reference -> (created_at, will_succeed, status)
_SANDBOX_STATE: dict[str, dict[str, Any]] = {}
_SANDBOX_DELAY_SECONDS = 3.0


# ─────────────────────────────────────────────────────────────────────────────
# Base class
# ─────────────────────────────────────────────────────────────────────────────


class MobileMoneyAdapter(ABC):
    operator: str  # "mpesa" | "airtel" | "orange" | "africell"
    display_name: str

    async def initiate(self, phone: str, amount_fc: int, reference: str) -> dict:
        if IS_SANDBOX:
            return self._sandbox_initiate(reference)
        return await self._live_initiate(phone, amount_fc, reference)

    async def status(self, operator_reference: str) -> dict:
        if IS_SANDBOX:
            return self._sandbox_status(operator_reference)
        return await self._live_status(operator_reference)

    # ── Sandbox fallback ────────────────────────────────────────────────────

    def _sandbox_initiate(self, reference: str) -> dict:
        op_ref = f"SBX-{self.operator.upper()}-{uuid.uuid4().hex[:10]}"
        # 90 % success rate in sandbox to also cover the failure path
        will_succeed = random.random() < 0.90
        _SANDBOX_STATE[op_ref] = {
            "created_at": time.time(),
            "will_succeed": will_succeed,
            "ref": reference,
        }
        return {
            "operator_reference": op_ref,
            "status": "pending",
            "mode": "sandbox",
            "message": f"[SANDBOX] {self.display_name} STK Push simulé. "
                       f"Confirmation automatique dans {_SANDBOX_DELAY_SECONDS:.0f}s.",
        }

    def _sandbox_status(self, op_ref: str) -> dict:
        state = _SANDBOX_STATE.get(op_ref)
        if state is None:
            return {"status": "failed", "raw": {"error": "unknown reference"}}
        elapsed = time.time() - state["created_at"]
        if elapsed < _SANDBOX_DELAY_SECONDS:
            return {"status": "pending", "raw": {"elapsed_s": round(elapsed, 1)}}
        return {
            "status": "completed" if state["will_succeed"] else "failed",
            "raw": {"sandbox": True, "elapsed_s": round(elapsed, 1)},
        }

    # ── To be implemented per-operator for production ───────────────────────

    @abstractmethod
    async def _live_initiate(self, phone: str, amount_fc: int, reference: str) -> dict:
        ...

    @abstractmethod
    async def _live_status(self, operator_reference: str) -> dict:
        ...


# ─────────────────────────────────────────────────────────────────────────────
# Vodacom M-Pesa RDC
# ─────────────────────────────────────────────────────────────────────────────


class VodacomMpesaAdapter(MobileMoneyAdapter):
    operator = "mpesa"
    display_name = "Vodacom M-Pesa"

    async def _live_initiate(self, phone: str, amount_fc: int, reference: str) -> dict:
        # TODO [M-Pesa DRC] : implémenter C2B Single Stage avec token OAuth
        # 1. POST https://openapi.m-pesa.com/openapi/ipg/v2/vodacomDRC/getSession
        #    Headers: Authorization: Bearer <api_key encrypted with public_key>
        # 2. POST https://openapi.m-pesa.com/openapi/ipg/v2/vodacomDRC/c2bPayment/singleStage
        #    Body: {
        #      "input_Amount": str(amount_fc),
        #      "input_Country": "DRC",
        #      "input_Currency": "CDF",
        #      "input_CustomerMSISDN": phone,  # 2438xxxxxxxx
        #      "input_ServiceProviderCode": VODACOM_MPESA_SERVICE_PROVIDER_CODE,
        #      "input_ThirdPartyConversationID": reference,
        #      "input_TransactionReference": reference,
        #      "input_PurchasedItemsDesc": "OmniFlix"
        #    }
        # Response ConversationID → operator_reference
        raise NotImplementedError(
            "Vodacom M-Pesa live mode not configured. "
            "Add VODACOM_MPESA_* credentials in backend/.env and implement _live_initiate.",
        )

    async def _live_status(self, operator_reference: str) -> dict:
        # TODO [M-Pesa DRC] : POST /c2bPayment/queryTransactionStatus
        raise NotImplementedError


# ─────────────────────────────────────────────────────────────────────────────
# Airtel Money RDC (via Airtel Africa API)
# ─────────────────────────────────────────────────────────────────────────────


class AirtelMoneyAdapter(MobileMoneyAdapter):
    operator = "airtel"
    display_name = "Airtel Money"
    BASE_URL = "https://openapiuat.airtel.africa"  # sandbox URL
    LIVE_URL = "https://openapi.airtel.africa"

    async def _live_initiate(self, phone: str, amount_fc: int, reference: str) -> dict:
        client_id = os.environ.get("AIRTEL_MONEY_CLIENT_ID")
        secret = os.environ.get("AIRTEL_MONEY_CLIENT_SECRET")
        if not client_id or not secret:
            raise NotImplementedError("Airtel Money credentials missing")

        async with httpx.AsyncClient(timeout=20) as c:
            # 1. OAuth token
            tok_res = await c.post(f"{self.LIVE_URL}/auth/oauth2/token", json={
                "client_id": client_id,
                "client_secret": secret,
                "grant_type": "client_credentials",
            })
            token = tok_res.json().get("access_token")

            # 2. Merchant Payment (STK)
            res = await c.post(
                f"{self.LIVE_URL}/merchant/v1/payments/",
                headers={
                    "Authorization": f"Bearer {token}",
                    "X-Country": "CD",
                    "X-Currency": "CDF",
                },
                json={
                    "reference": reference,
                    "subscriber": {
                        "country": "CD",
                        "currency": "CDF",
                        "msisdn": phone,
                    },
                    "transaction": {
                        "amount": amount_fc,
                        "country": "CD",
                        "currency": "CDF",
                        "id": reference,
                    },
                },
            )
            data = res.json() or {}
            return {
                "operator_reference": data.get("data", {}).get("transaction", {}).get("id", reference),
                "status": "pending",
                "raw": data,
            }

    async def _live_status(self, operator_reference: str) -> dict:
        # GET /standard/v1/payments/{operator_reference}
        raise NotImplementedError("Airtel Money status check not yet wired")


# ─────────────────────────────────────────────────────────────────────────────
# Orange Money RDC
# ─────────────────────────────────────────────────────────────────────────────


class OrangeMoneyAdapter(MobileMoneyAdapter):
    operator = "orange"
    display_name = "Orange Money"

    async def _live_initiate(self, phone: str, amount_fc: int, reference: str) -> dict:
        # TODO [Orange Money RDC] : Web Payment API
        # 1. POST https://api.orange.com/oauth/v3/token (Basic auth clientId:secret)
        # 2. POST https://api.orange.com/orange-money-webpay/cd/v1/webpayment
        #    Body: { merchant_key, currency: "CDF", order_id, amount, ... }
        #    → response contient payment_url à ouvrir dans un WebView
        raise NotImplementedError(
            "Orange Money live mode not configured. Add ORANGE_MONEY_* credentials.",
        )

    async def _live_status(self, operator_reference: str) -> dict:
        raise NotImplementedError


# ─────────────────────────────────────────────────────────────────────────────
# Africell Money
# ─────────────────────────────────────────────────────────────────────────────


class AfricellMoneyAdapter(MobileMoneyAdapter):
    operator = "africell"
    display_name = "Africell Money"

    async def _live_initiate(self, phone: str, amount_fc: int, reference: str) -> dict:
        # TODO [Africell Money] : API publique sur demande commerciale
        # Contactez partnerships@africell.cd pour obtenir les specs API
        raise NotImplementedError(
            "Africell Money live mode not configured. Contact Africell partnerships.",
        )

    async def _live_status(self, operator_reference: str) -> dict:
        raise NotImplementedError


# ─────────────────────────────────────────────────────────────────────────────
# Registry
# ─────────────────────────────────────────────────────────────────────────────


ADAPTERS: dict[str, MobileMoneyAdapter] = {
    "mpesa":    VodacomMpesaAdapter(),
    "airtel":   AirtelMoneyAdapter(),
    "orange":   OrangeMoneyAdapter(),
    "africell": AfricellMoneyAdapter(),
}


def get_adapter(operator: str) -> MobileMoneyAdapter:
    adapter = ADAPTERS.get(operator.lower())
    if adapter is None:
        raise ValueError(f"Unknown operator: {operator}")
    return adapter
