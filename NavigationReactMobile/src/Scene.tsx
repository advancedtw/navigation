import * as React from 'react';
import { State } from 'navigation';
import { NavigationContext, NavigationEvent } from 'navigation-react';
import withStateNavigator from './withStateNavigator';
import { SceneProps } from './Props';
type SceneState = { navigationEvent: NavigationEvent };

class Scene extends React.Component<SceneProps & {navigationEvent: NavigationEvent}, SceneState> {
    constructor(props) {
        super(props);
        this.state = {navigationEvent: null};
    }
    static defaultProps = {
        renderScene: (state: State, data: any) => state.renderScene(data)
    }
    static getDerivedStateFromProps(props: SceneProps & {navigationEvent: NavigationEvent}, {navigationEvent: prevNavigationEvent}: SceneState) {
        var {url, crumb, navigationEvent} = props;
        var {url: currentUrl, state, oldState, oldUrl} = navigationEvent.stateNavigator.stateContext;
        if (!state || url !== currentUrl)
            return null;
        if (!oldUrl || !prevNavigationEvent)
            return {navigationEvent};
        var {crumbs: oldCrumbs} = navigationEvent.stateNavigator.parseLink(oldUrl);
        var replace = oldCrumbs.length === crumb && oldState !== state;
        return !replace ? {navigationEvent} : null;
    }
    shouldComponentUpdate({crumb, rest, navigationEvent: {stateNavigator}}, nextState) {
        var {crumbs} = stateNavigator.stateContext;
        var freezableOrCurrent = rest && (!!React.Suspense || crumbs.length === crumb);
        return freezableOrCurrent || nextState.navigationEvent !== this.state.navigationEvent;
    }
    render() {
        var {navigationEvent} = this.state;
        var {crumb, navigationEvent: {stateNavigator}, className, style} = this.props;
        var {crumbs} = stateNavigator.stateContext;
        var stateContext = navigationEvent?.stateNavigator?.stateContext;
        var {state, data} = stateContext || crumbs[crumb] || {};
        return (
            <NavigationContext.Provider value={navigationEvent}>
                <div data-scene="true" className={className}
                    style={{...style, display: navigationEvent ? 'flex' : 'none', height: '100%', flexDirection: 'column'}}>
                    {navigationEvent && this.props.renderScene(state, data)}
                </div>
            </NavigationContext.Provider>
        );
    }
}

export default withStateNavigator(Scene);
