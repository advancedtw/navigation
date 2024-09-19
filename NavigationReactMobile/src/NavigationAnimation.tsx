import React, {useRef, useState, useLayoutEffect} from 'react';

const NavigationAnimation  = ({children, data: nextScenes, onRest, oldState, duration: defaultDuration}) => {
    const [scenes, setScenes] = useState({prev: null, all: [], count: 0});
    const container = useRef(null);
    useLayoutEffect(() => {
        let cancel = false;
        scenes.all.forEach(({key, pushEnter, popExit, pushExit, popEnter, unmountStyle, crumbStyle}, i) => {
            const scene = container.current.children[i];
            const prevNavState = scene.navState || scene.prevNavState;
            if (!scene.animate) {
                if (popExit)
                    setScenes(({all, ...rest}) => ({all: all.filter((_s, index) => index !== i), ...rest}))
                if (pushEnter && prevNavState !== 'pushEnter')
                    onRest({key})
                if (popEnter && prevNavState !== 'popEnter')
                    onRest({key})
                scene.prevNavState = pushEnter ? 'pushEnter' : popExit ? 'popExit' : pushExit ? 'pushExit' : 'popEnter';
                return;
            };
            const afterPushEnter = scene.pushEnter?.finished || {then: (f) => f()};
            const afterPopEnter = scene.popEnter?.finished || {then: (f) => f()};
            afterPopEnter.then(() => {
                if (cancel) return;
                if (!scene.pushEnter) {
                    const {duration = defaultDuration, keyframes = unmountStyle} = unmountStyle;
                    scene.pushEnter = scene.animate(keyframes, {duration, fill: 'forwards'});
                    scene.pushEnter.persist();
                }
                if (pushEnter && prevNavState !== 'pushEnter') {
                    scene.navState = 'pushEnter';
                    if (oldState) {
                        if (prevNavState === 'popExit') scene.pushEnter.reverse();
                        else if (prevNavState) scene.pushEnter.finish();
                        else scene.pushEnter.play();
                    } else {
                        scene.pushEnter.finish();
                    }
                }
                if (popExit && prevNavState !== 'popExit') {
                    scene.navState = 'popExit';
                    scene.pushEnter.reverse();
                }
                scene.pushEnter?.finished.then(() => {
                    if (cancel || !scene.navState) return;
                    if (popExit)
                        setScenes(({all, ...rest}) => ({all: all.filter((_s, index) => index !== i), ...rest}))
                    if (pushEnter || popExit) {
                        onRest({key});
                        scene.prevNavState = scene.navState;
                        scene.navState = undefined;
                    }
                });
            });
            afterPushEnter.then(() => {
                if (cancel) return;
                if (!scene.popEnter && (pushExit || popEnter)) {       
                    const {duration = defaultDuration, keyframes = crumbStyle} = crumbStyle;
                    scene.popEnter = scene.animate(keyframes, {duration, fill: 'backwards'});
                    scene.popEnter.persist();
                }
                if (popEnter && prevNavState !== 'popEnter') {
                    scene.navState = 'popEnter';
                    if (prevNavState === 'pushExit') scene.popEnter.reverse();
                    else if (prevNavState) scene.popEnter.finish();
                    else scene.popEnter.play();
                }
                if (pushExit && prevNavState !== 'pushExit') {
                    scene.navState = 'pushExit';
                    scene.popEnter.reverse();
                }
                scene.popEnter?.finished.then(() => {
                    if (cancel || !scene.navState) return;
                    if (pushExit || popEnter) {
                        onRest({key});
                        scene.prevNavState = scene.navState;
                        scene.navState = undefined;
                    }
                });
            });
        });
        return () => {cancel = true;}
    }, [scenes]);
    if (nextScenes !== scenes.prev) {
        setScenes(({all: scenes, count}) => {
            const scenesByKey = scenes.reduce((acc, scene) => ({...acc, [scene.key]: scene}), {});
            const nextScenesByKey = nextScenes.reduce((acc, scene) => ({...acc, [scene.key]: scene}), {});
            const noAnim = {pushEnter: false, pushExit: false, popEnter: false, popExit: false};
            return {
                prev: nextScenes,
                count: count + 1,
                all: nextScenes
                    .map((nextScene) => {
                        const scene = scenesByKey[nextScene.key];
                        const wasMounted = !!scene?.pushEnter || !!scene?.popEnter;
                        const noAnimScene = {...scene, ...nextScene, ...noAnim};
                        if (!scene) return {...noAnimScene, pushEnter: true, count};
                        if (nextScene.mount && !wasMounted) return {...noAnimScene, popEnter: !scene.popExit, pushEnter: scene.popExit};
                        if (!nextScene.mount && wasMounted) return {...noAnimScene, pushExit: true};
                        return {...scene, ...nextScene};
                    })
                    .concat(scenes
                        .filter(scene => !nextScenesByKey[scene.key])
                        .map(scene => ({...scene, ...noAnim, popExit: !scene.pushExit, popEnter: scene.pushExit}))
                    )
                    .sort((a, b) => a.index !== b.index ? a.index - b.index : a.count - b.count)
            };
        });
    };
    return <div ref={container}>{children(scenes.all)}</div>;
}

export default NavigationAnimation;
