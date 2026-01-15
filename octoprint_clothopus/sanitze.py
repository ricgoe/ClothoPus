from typing import Any, Dict

Schema = Dict[str, Any]
SCHEMA: Schema = {
    "stacks": {
        "*": {
            "name": str,
            "nfc": {
                "baud": int,
                "busy": int,
                "nss": int,
                "reset": int,
                "spi_channel": int,
            },
            "scale": {
                "calib": {
                    "offset": float,
                    "scale": float,
                },
                "pins": {
                    "dout": int,
                    "gain": int,
                    "pd_sck": int,
                },
            },
        }
    }
}

def sanitize_patch(patch: dict) -> dict:
    def walk(node: Any, schema: Any) -> Any:
        if isinstance(schema, type):
            try:
                return schema(node)
            except Exception:
                return node  # or raise if you want strict behavior
        if isinstance(node, dict) and isinstance(schema, dict):
            out = dict(node)
            wildcard_schema = schema.get("*")
            for k, v in node.items():
                if k in schema:
                    out[k] = walk(v, schema[k])
                elif wildcard_schema is not None:
                    out[k] = walk(v, wildcard_schema)
            return out
        return node

    return walk(patch, SCHEMA)