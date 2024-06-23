import React, { useMemo, useContext, useState, useRef } from 'react';
import { requireNativeComponent, StyleSheet, View, Platform, UIManager } from 'react-native';
import { NavigationContext } from 'navigation-react';
import FragmentContext from './FragmentContext';

const Dialog = ({detent, defaultDetent = 'collapsed', expandedHeight, expandedOffset, modal = true, onChangeDetent, children}) => {
    const [sheetState, setSheetState]  = useState({selectedDetent: detent || defaultDetent, mostRecentEventCount: 0, dismissed: (detent || defaultDetent) === 'hidden'})
    const dragging = useRef(false);
    const changeDetent = (selectedDetent) => {
        if (sheetState.selectedDetent !== selectedDetent) {
            if (detent == null)
                setSheetState(prevSheetState => ({...prevSheetState, selectedDetent}));
            if (!!onChangeDetent)
                onChangeDetent(selectedDetent);
        }
    }
    const _stackId = React.useId?.();
    const stackId = useMemo(() => _stackId ? `${_stackId}${modal}` : undefined, [_stackId, modal]);
    const ancestorStackIds = useContext(FragmentContext);
    const navigationEvent = useContext(NavigationContext);
    const stackIds = useMemo(() => stackId ? [...ancestorStackIds, stackId] : [], [ancestorStackIds, stackId]);
    if (detent != null && detent !== sheetState.selectedDetent)
        setSheetState(prevSheetState => ({...prevSheetState, selectedDetent: detent, dismissed: detent === 'hidden' && sheetState.dismissed}));
    const detents = (UIManager as any).getViewManagerConfig('NVBottomSheet').Constants?.Detent;
    const onDetentChanged = ({nativeEvent}) => {
        const {eventCount: mostRecentEventCount, detent: nativeDetent} = nativeEvent;
        const selectedDetent = Platform.OS === 'android'? Object.keys(detents).find(name => detents[name] === nativeDetent) : nativeDetent;
        dragging.current = !selectedDetent;
        if (selectedDetent) {
            changeDetent(selectedDetent);
            setSheetState(prevSheetState => ({...prevSheetState, mostRecentEventCount}));
        }
    }
    if (sheetState.dismissed && sheetState.selectedDetent === 'hidden') return null;
    const DialogView = modal ? NVDialog : NVSheet;
    const crumb = navigationEvent.stateNavigator.stateContext.crumbs.length;
    return (
        <FragmentContext.Provider value={stackIds}>
            <DialogView
                detent={Platform.OS === 'android' ? '' + detents[sheetState.selectedDetent] : sheetState.selectedDetent}
                dismissed={sheetState.dismissed}
                stackId={stackId}
                ancestorStackIds={ancestorStackIds}
                expandedOffset={expandedOffset}
                sheetHeight={expandedHeight != null ? expandedHeight : 0}
                crumb={crumb}
                mostRecentEventCount={sheetState.mostRecentEventCount}
                onMoveShouldSetResponderCapture={() => dragging.current}
                onDetentChanged={onDetentChanged}
                onDismissed={() => setSheetState(prevSheetState => ({...prevSheetState, dismissed: true}))}
                style={[
                    styles.dialog,
                    expandedHeight != null ? { height: expandedHeight } : null,
                    expandedOffset != null ? { top: expandedOffset } : null,
                    expandedHeight == null && expandedOffset == null ? { top: 0 } : null,
                    Platform.OS === 'ios' || modal ? { height: undefined, top: undefined } : null, 
                ]}
            >
                {children}
            </DialogView>
        </FragmentContext.Provider>
    )
}

const NVDialog = requireNativeComponent<any>('NVDialog');
const NVSheet = requireNativeComponent<any>('NVSheet');

const styles = StyleSheet.create({
    dialog: {
        position: 'absolute',
        elevation: 5,
        backgroundColor: 'transparent',
        right: 0, bottom: 0, left: 0
    },
});

export default Dialog;
