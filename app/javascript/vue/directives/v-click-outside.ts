import { Directive } from 'vue';

type Handler = (e: Event) => void;

const isEventOutside = (el: HTMLElement, event: Event) => {
    const path = (event as any).composedPath?.() as EventTarget[] | undefined;
    if (path) return !path.includes(el);
    return !(el === event.target || el.contains(event.target as Node));
};

const useListener = (el: HTMLElement, handler: Handler, eventName = 'pointerdown') => {
    const listener = (e: Event) => {
        if (isEventOutside(el, e)) handler(e);
    };
    document.addEventListener(eventName, listener);
    return () => document.removeEventListener(eventName, listener);
};

const ClickOutside: Directive<HTMLElement, Handler | { handler: Handler; event?: string }> = {
    beforeMount(el, binding) {
        const value = binding.value;
        const handler = typeof value === 'function' ? value : value?.handler;
        const event = typeof value === 'object' && value?.event ? value.event : 'pointerdown';

        if (typeof handler !== 'function') {
            // eslint-disable-next-line no-console
            console.warn('[v-click-outside] provided expression is not a function');
            return;
        }

        (el as any).__clickOutsideCleanup__ = useListener(el, handler, event);
    },
    unmounted(el) {
        const cleanup = (el as any).__clickOutsideCleanup__;
        if (typeof cleanup === 'function') cleanup();
        delete (el as any).__clickOutsideCleanup__;
    },
};

export default ClickOutside;
