import React, {useRef, useState, useContext, useEffect, ReactElement} from 'react';
import { State, StateNavigator } from 'navigation';
import { NavigationContext } from 'navigation-react';
import Scene from './Scene';
import Freeze from './Freeze';
import NavigationAnimation from './NavigationAnimation';
import { NavigationMotionProps as NavigationStackProps } from './Props';
type NavigationStackState = {stateNavigator: StateNavigator, keys: string[], rest: boolean};

const NavigationStack = ({unmountStyle: unmountStyleStack, crumbStyle: crumbStyleStack, duration = 300, renderScene, children, stackInvalidatedLink, renderMotion = children}: NavigationStackProps) => {
    const {stateNavigator} = useContext(NavigationContext);
    const [motionState, setMotionState] = useState<NavigationStackState>({stateNavigator: null, keys: [], rest: false});
    const scenes = {};
    let firstLink;
    const findScenes = (elements = children, nested = false) => {
        for(const scene of React.Children.toArray(elements) as ReactElement<any>[]) {
            const {stateKey, children} = scene.props;
            if (scene.type === NavigationStack.Scene) {
                firstLink = firstLink || stateNavigator.fluent().navigate(stateKey).url;
                scenes[stateKey] = scene;
            }
            else if (!nested) findScenes(children, true)
        }
    }
    findScenes();
    const prevScenes = useRef({});
    const allScenes = {...prevScenes.current, ...scenes};
    useEffect(() => {
        prevScenes.current = allScenes;
        const {state, crumbs, nextCrumb} = stateNavigator.stateContext;
        const validate = ({key}) => !!scenes[key];
        if (firstLink) {
            stateNavigator.onBeforeNavigate(validate);
            let resetLink = !state ? firstLink : undefined;
            if (!resetLink && [...crumbs, nextCrumb].find(({state}) => !scenes[state.key]))
                resetLink = stackInvalidatedLink != null ? stackInvalidatedLink : firstLink;
            if (resetLink != null) stateNavigator.navigateLink(resetLink);
        }
        return () => stateNavigator.offBeforeNavigate(validate);
    }, [children, stateNavigator, scenes, allScenes, stackInvalidatedLink]);
    const clearScene = ({key}) => {
        setMotionState(({rest: prevRest, stateNavigator, keys}) => {
            const scene = getScenes().filter(scene => scene.key === key)[0];
            var rest = prevRest || (scene && scene.mount);
            return {rest, stateNavigator, keys};
        });
    }
    const getScenes = () => {
        const {keys} = motionState;
        const {crumbs, nextCrumb} = stateNavigator.stateContext;
        return crumbs.concat(nextCrumb).map(({state, data, url}, index, crumbsAndNext) => {
            const preCrumbs = crumbsAndNext.slice(0, index);
            const {state: nextState, data: nextData} = crumbsAndNext[index + 1] || {state: undefined, data: undefined};
            const mount = url === nextCrumb.url;
            return {key: keys[index], index, mount, unmountStyle: unmountStyle(state, data, preCrumbs), crumbStyle: crumbStyle(state, data, preCrumbs, nextState, nextData)};
        });
    }
    const sceneProps = ({key}: State) => firstLink ? allScenes[key].props : null;
    const returnOrCall = (item, ...args) => typeof item !== 'function' ? item : item(...args);
    const unmountStyle = (state, ...rest) => sceneProps(state)?.unmountStyle ? returnOrCall(sceneProps(state)?.unmountStyle, ...rest) : returnOrCall(unmountStyleStack, state, ...rest);
    const crumbStyle = (state, ...rest) => sceneProps(state)?.crumbStyle ? returnOrCall(sceneProps(state)?.crumbStyle, ...rest) : returnOrCall(crumbStyleStack, state, ...rest);
    const {stateNavigator: prevStateNavigator} = motionState;
    if (prevStateNavigator !== stateNavigator && stateNavigator.stateContext.state) {
        setMotionState((prevStackState) => {
            const {keys: prevKeys, stateNavigator: prevStateNavigator} = prevStackState;
            const {state, crumbs, nextCrumb} = stateNavigator.stateContext;
            const prevState = prevStateNavigator && prevStateNavigator.stateContext.state;
            const currentKeys = crumbs.concat(nextCrumb).reduce((arr, {state: {key}}) => {
                const prevKey = arr[arr.length - 1];
                return [...arr, `${prevKey ? `${prevKey}->` : ''}${key.replace(/-/g, '-|')}`]
            }, []);
            const newKeys = currentKeys.slice(prevKeys.length);
            const keys = prevKeys.slice(0, currentKeys.length).concat(newKeys);
            if (prevKeys.length === keys.length && prevState !== state)
                keys[keys.length - 1] = currentKeys[keys.length - 1];
            return {keys, rest: false, stateNavigator};
        })
    }
    const {stateContext: {oldState}, stateContext} = stateNavigator;
    renderScene = firstLink ? ({key}) => allScenes[key] : renderScene;
    return (stateContext.state &&
        <NavigationAnimation data={getScenes()} onRest={clearScene} oldState={oldState} duration={duration}>
            {scenes => (
                scenes.map(({key, index: crumb}) => (
                    <Freeze key={key} enabled={motionState.rest && crumb < getScenes().length - 1}>
                        <Scene crumb={crumb} id={key} rest renderScene={renderScene} />
                    </Freeze>
                ))
            )}
        </NavigationAnimation>
    )
}

NavigationStack.Scene = ({children}) => children;

export default NavigationStack;
