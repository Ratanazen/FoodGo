from django.apps import AppConfig


class CoreConfig(AppConfig):
    name = 'core'

    def ready(self):
        try:
            import pillow_heif
            pillow_heif.register_heif_opener()
        except ImportError:
            pass

        try:
            import core.signals  # noqa: F401
        except Exception:
            pass
