import { ref } from 'vue';

export interface Notification {
    id: number;
    type: 'success' | 'error' | 'notice' | 'alert' | 'warning';
    message: string;
    duration?: number;
}

const notifications = ref<Notification[]>([]);
let nextId = 0;

export const useNotifications = () => {
    const addNotification = (
        type: Notification['type'],
        message: string,
        duration: number = 5000
    ) => {
        const id = nextId++;
        notifications.value.push({ id, type, message, duration });
        return id;
    };

    const removeNotification = (id: number) => {
        const index = notifications.value.findIndex(n => n.id === id);
        if (index > -1) {
            notifications.value.splice(index, 1);
        }
    };

    const clearAll = () => {
        notifications.value = [];
    };

    // Métodos auxiliares
    const success = (message: string, duration?: number) =>
        addNotification('success', message, duration);

    const error = (message: string, duration?: number) =>
        addNotification('error', message, duration);

    const notice = (message: string, duration?: number) =>
        addNotification('notice', message, duration);

    const alert = (message: string, duration?: number) =>
        addNotification('alert', message, duration);

    const warning = (message: string, duration?: number) =>
        addNotification('warning', message, duration);

    return {
        notifications,
        addNotification,
        removeNotification,
        clearAll,
        success,
        error,
        notice,
        alert,
        warning
    };
};

