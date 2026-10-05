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

    // Initialize on DOM ready
    if (document.readyState === 'loading') {
        document.addEventListener('DOMContentLoaded', function() {
            loadSvgIcons();
            observeDynamicIcons();
        });
    } else {
        loadSvgIcons();
        observeDynamicIcons();
    }
})();
