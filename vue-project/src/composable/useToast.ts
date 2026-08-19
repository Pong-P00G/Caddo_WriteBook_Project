import { ref } from "vue";

export interface ToastItem {
    id: string;
    title: string;
    description?: string;
    type: "success" | "error" | "info" | "warning";
    duration?: number;
}

const toasts = ref<ToastItem[]>([]);

export function useToast() {
    function addToast(item: Omit<ToastItem, "id">) {
        const id = Math.random().toString(36).substring(2, 9);
        const duration = item.duration ?? 3500;
        const toast: ToastItem = { ...item, id };
        toasts.value.push(toast);

        if (duration > 0) {
            setTimeout(() => {
                removeToast(id);
            }, duration);
        }
        return id;
    }

    function removeToast(id: string) {
        const index = toasts.value.findIndex((t) => t.id === id);
        if (index !== -1) {
            toasts.value.splice(index, 1);
        }
    }

    function success(title: string, description?: string, duration = 3500) {
        return addToast({ title, description, type: "success", duration });
    }

    function error(title: string, description?: string, duration = 4500) {
        return addToast({ title, description, type: "error", duration });
    }

    function info(title: string, description?: string, duration = 3500) {
        return addToast({ title, description, type: "info", duration });
    }

    function warning(title: string, description?: string, duration = 4000) {
        return addToast({ title, description, type: "warning", duration });
    }

    return {
        toasts,
        addToast,
        removeToast,
        success,
        error,
        info,
        warning,
    };
}
