"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.useOfflineQueue = useOfflineQueue;
const react_1 = require("react");
const useMultando_1 = require("./useMultando");
function useOfflineQueue() {
    const { client } = (0, useMultando_1.useMultando)();
    const [count, setCount] = (0, react_1.useState)(client.offlineQueueCount);
    const [items, setItems] = (0, react_1.useState)(client.offlineQueueItems);
    const [isFlushing, setIsFlushing] = (0, react_1.useState)(false);
    const refreshState = (0, react_1.useCallback)(() => {
        setCount(client.offlineQueueCount);
        setItems(client.offlineQueueItems);
    }, [client]);
    (0, react_1.useEffect)(() => {
        const unsubscribe = client.onEvent((event, data) => {
            if (event === 'offline_queue_changed') {
                refreshState();
                const detail = data;
                if (detail?.event === 'flushing') {
                    setIsFlushing(true);
                }
                else if (detail?.event === 'flushed' ||
                    detail?.event === 'flush_error') {
                    setIsFlushing(false);
                }
            }
        });
        return unsubscribe;
    }, [client, refreshState]);
    const flush = (0, react_1.useCallback)(async () => {
        setIsFlushing(true);
        try {
            await client.flushOfflineQueue();
        }
        finally {
            setIsFlushing(false);
            refreshState();
        }
    }, [client, refreshState]);
    const remove = (0, react_1.useCallback)(async (id) => {
        await client.removeFromOfflineQueue(id);
        refreshState();
    }, [client, refreshState]);
    return {
        count,
        items,
        isFlushing,
        flush,
        remove,
    };
}
//# sourceMappingURL=useOfflineQueue.js.map