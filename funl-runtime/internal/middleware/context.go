package middleware

import (
    "context"

    "github.com/golang-jwt/jwt/v5"
)

type CtxKey string

const (
    CtxKeyCorrelationID CtxKey = "correlation_id"
    CtxKeyJWTClaims      CtxKey = "jwt_claims"
)

func GetCorrelationID(ctx context.Context) string {
    v := ctx.Value(CtxKeyCorrelationID)
    if s, ok := v.(string); ok {
        return s
    }
    return "unknown"
}

// GetJWTClaims retrieves JWT claims stored in the context.
func GetJWTClaims(ctx context.Context) jwt.MapClaims {
    v := ctx.Value(CtxKeyJWTClaims)
    if v == nil {
        return nil
    }

    // Case 1: actual jwt.MapClaims (most common)
    if claims, ok := v.(jwt.MapClaims); ok {
        return claims
    }

    // Case 2: plain map[string]interface{}
    if m, ok := v.(map[string]interface{}); ok {
        return jwt.MapClaims(m)
    }

    return nil
}

func GetJWTClaimString(ctx context.Context, key string) string {
    claims := GetJWTClaims(ctx)
    if claims == nil {
        return ""
    }
    if s, ok := claims[key].(string); ok {
        return s
    }
    return ""
}

func GetJWTRole(ctx context.Context) string {
    return GetJWTClaimString(ctx, "role")
}
