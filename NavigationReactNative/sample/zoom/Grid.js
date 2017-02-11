import React from 'react';
import {StyleSheet, ScrollView, Text, View, TouchableHighlight} from 'react-native';

const colors = ['maroon', 'red', 'crimson', 'orange', 'brown',
  'sienna', 'olive', 'purple', 'fuchsia', 'indigo',
  'green', 'navy', 'blue', 'teal', 'black'];

export default ({stateNavigator}) => (
  <View style={styles.grid}>
    <ScrollView>
      <View style={styles.colors}>
        {colors.map(color => (
          <TouchableHighlight
            key={color}
            style={[
              {backgroundColor: color},
              styles.color
            ]}
            underlayColor={color}
            onPress={() => {
              stateNavigator.navigate('detail', {color: color});
            }}>
            <Text></Text>
          </TouchableHighlight>
        ))}
      </View>
    </ScrollView>
  </View>
);

const styles = StyleSheet.create({
  grid: {
    flex: 1,
    backgroundColor: '#fff',
  },
  colors: {
    flexDirection: 'row',
    flexWrap: 'wrap',
    justifyContent: 'center',
    marginTop: 50,
  },
  color: {
    width: 100,
    height: 150,
    margin: 10,
  },
});
