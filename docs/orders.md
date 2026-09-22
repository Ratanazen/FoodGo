# 📦 Order Management & Lifecycle

## Order States
```
[PENDING]
    │ (Payment Verified or COD Selected)
    ▼
[CONFIRMED]
    │ (Restaurant starts cooking)
    ▼
[PREPARING]
    │ (Food ready for pickup)
    ▼
[READY_FOR_PICKUP]
    │ (Driver accepts & picks up)
    ▼
[PICKED_UP] ──▶ [ON_THE_WAY]
                    │
                    ▼
               [DELIVERED]
```

## Security & State Progression
- Customers can only review orders once status is `delivered`.
- Status transitions can only be triggered by the authorized restaurant owner or assigned delivery driver.
