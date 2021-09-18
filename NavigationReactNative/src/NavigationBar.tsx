import React, { ReactElement } from 'react';
import { requireNativeComponent, Platform, Animated } from 'react-native';
import LeftBar from './LeftBar';
import RightBar from './RightBar';
import SearchBar from './SearchBar';
import TitleBar from './TitleBar';
import CollapsingBar from './CollapsingBar';
import TabBar from './TabBar';
import StatusBar from './StatusBar';
import Toolbar from './Toolbar';

class NavigationBar extends React.Component<any, any> {
    constructor(props) {
        super(props);
    }
    getScrollEdgeProps() {
        var {barTintColor, titleColor, titleFontFamily, titleFontWeight, titleFontStyle, titleFontSize } = this.props;
        return {
            barTintColor: typeof barTintColor === 'function' ? barTintColor(true) : barTintColor,
            largeBarTintColor: typeof barTintColor === 'function' ? barTintColor(false) : barTintColor,
            titleColor: typeof titleColor === 'function' ? titleColor(true) : titleColor,
            largeTitleColor: typeof titleColor === 'function' ? titleColor(false) : titleColor,
            titleFontFamily: typeof titleFontFamily === 'function' ? titleFontFamily(true) : titleFontFamily,
            largeTitleFontFamily: typeof titleFontFamily === 'function' ? titleFontFamily(false) : titleFontFamily,
            titleFontWeight: typeof titleFontWeight === 'function' ? titleFontWeight(true) : titleFontWeight,
            largeTitleFontWeight: typeof titleFontWeight === 'function' ? titleFontWeight(false) : titleFontWeight,
            titleFontStyle: typeof titleFontStyle === 'function' ? titleFontStyle(true) : titleFontStyle,
            largeTitleFontStyle: typeof titleFontStyle === 'function' ? titleFontStyle(false) : titleFontStyle,
            titleFontSize: typeof titleFontSize === 'function' ? titleFontSize(true) : titleFontSize,
            largeTitleFontSize: typeof titleFontSize === 'function' ? titleFontSize(false) : null,
        }
    }
    render() {
        var {hidden, children, style = {height: undefined}, ...otherProps} = this.props;
        var scrollEdgeProps = this.getScrollEdgeProps()
        var childrenArray = (React.Children.toArray(children) as ReactElement<any>[]);
        var statusBar = childrenArray.find(({type}) => type === StatusBar);
        statusBar = (Platform.OS === 'android' || !statusBar) && (statusBar || <StatusBar />);
        if (Platform.OS === 'android' && hidden)
            return statusBar;
        var collapsingBar = Platform.OS === 'android' && childrenArray.find(({type}) => type === CollapsingBar);
        return (
            <>
                <NVNavigationBar
                    hidden={hidden}
                    style={{height: !!collapsingBar ? style.height : null}}                    
                    {...otherProps}
                    {...scrollEdgeProps}
                    barTintColor={!collapsingBar ? scrollEdgeProps.barTintColor : scrollEdgeProps.largeBarTintColor}>
                    {Platform.OS === 'ios' ? !hidden && children :
                        <Container
                            collapse={!!collapsingBar}
                            {...otherProps}
                            {...scrollEdgeProps}
                            {...(collapsingBar && collapsingBar.props)}>
                            {collapsingBar && collapsingBar.props.children}
                            <Toolbar
                                bottom={false}
                                pin={!!collapsingBar}
                                {...otherProps}
                                {...scrollEdgeProps}
                                barTintColor={!collapsingBar ? scrollEdgeProps.barTintColor : null}>
                                {[
                                    childrenArray.find(({type}) => type === TitleBar),
                                    childrenArray.find(({type}) => type === LeftBar),
                                    childrenArray.find(({type}) => type === RightBar)
                                ]}
                            </Toolbar>
                            {childrenArray.find(({type}) => type === TabBar)}
                        </Container>}
                        {statusBar}
                </NVNavigationBar>
                {Platform.OS === 'ios' ? null : childrenArray.find(({type}) => type === SearchBar)}
            </>
        )
    }
}

var Container: any = ({collapse, children, ...props}) => (
    !collapse ? children : <CollapsingBar {...props}>{children}</CollapsingBar>
)

var NVNavigationBar = requireNativeComponent<any>('NVNavigationBar', null);

export default Animated.createAnimatedComponent(NavigationBar);