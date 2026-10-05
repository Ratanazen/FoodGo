/**
 * FoodGo Admin - SVG Vector Icon Engine
 * Automatically upgrades all admin icons to crisp vector SVGs
 */
(function() {
    'use strict';

    // 1. Load FontAwesome 6 SVG + JavaScript Bundle
    function loadSvgIcons() {
        if (window.FontAwesome) {
            if (window.FontAwesome.dom && window.FontAwesome.dom.i2svg) {
                window.FontAwesome.dom.i2svg();
            }
            return;
        }

        window.FontAwesomeConfig = {
            autoReplaceSvg: 'nest',
            observeMutations: true,
            searchPseudoElements: false
        };

        const script = document.createElement('script');
        script.src = 'https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.5.1/js/all.min.js';
        script.async = true;
        script.crossOrigin = 'anonymous';
        script.onload = function() {
            if (window.FontAwesome && window.FontAwesome.dom && window.FontAwesome.dom.i2svg) {
                window.FontAwesome.dom.i2svg();
            }
        };
        document.head.appendChild(script);
    }

    // 2. Observer for dynamically injected DOM nodes (modals, inline formsets, AJAX filters)
    function observeDynamicIcons() {
        if (!window.MutationObserver) return;

        const observer = new MutationObserver(function(mutations) {
            let hasNewIcons = false;
            for (let i = 0; i < mutations.length; i++) {
                const added = mutations[i].addedNodes;
                for (let j = 0; j < added.length; j++) {
                    const node = added[j];
                    if (node.nodeType === 1 && (node.matches('i.fa, i.fas, i.far, i.fab') || node.querySelector('i.fa, i.fas, i.far, i.fab'))) {
                        hasNewIcons = true;
                        break;
                    }
                }
                if (hasNewIcons) break;
            }

            if (hasNewIcons && window.FontAwesome && window.FontAwesome.dom && window.FontAwesome.dom.i2svg) {
                window.FontAwesome.dom.i2svg();
            }
        });

        observer.observe(document.body, { childList: true, subtree: true });
    }

    // 3. Real-time CSRF sync on form submission
    // Guarantees the form always submits the currently active csrftoken cookie,
    // completely preventing "CSRF token from POST incorrect" errors if a token
    // was rotated in another tab or after authentication.
    function setupCsrfSync() {
        document.addEventListener('submit', function(e) {
            var form = e.target;
            if (!form || !form.querySelector) return;
            var csrfInput = form.querySelector('input[name="csrfmiddlewaretoken"]');
            if (csrfInput) {
                var match = document.cookie.match(/(^|;)\s*csrftoken=([^;]+)/);
                if (match && match[2]) {
                    var currentToken = decodeURIComponent(match[2]);
                    if (currentToken && currentToken.length >= 32) {
                        csrfInput.value = currentToken;
                    }
                }
            }
        }, true);

        if (window.jQuery) {
            window.jQuery(document).ajaxSend(function(event, xhr, settings) {
                if (!(/^http:.*/.test(settings.url) || /^https:.*/.test(settings.url))) {
                    var match = document.cookie.match(/(^|;)\s*csrftoken=([^;]+)/);
                    if (match && match[2]) {
                        xhr.setRequestHeader("X-CSRFToken", decodeURIComponent(match[2]));
                    }
                }
            });
        }
    }

    // Initialize on DOM ready
    if (document.readyState === 'loading') {
        document.addEventListener('DOMContentLoaded', function() {
            loadSvgIcons();
            observeDynamicIcons();
            setupCsrfSync();
        });
    } else {
        loadSvgIcons();
        observeDynamicIcons();
        setupCsrfSync();
    }
})();
