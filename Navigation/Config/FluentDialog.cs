﻿using System;
using System.Collections.Generic;
using System.ComponentModel;

namespace Navigation
{
	public abstract class FluentDialog
	{
		private string _Title;
		private string _ResourceType;
		private string _ResourceKey;
		private List<KeyValuePair<string, string>> _Attributes = new List<KeyValuePair<string, string>>();

		internal string Key
		{
			get;
			private set;
		}

		internal IEnumerable<FluentState> States
		{
			get;
			private set;
		}

		internal FluentState Initial
		{
			get;
			private set;
		}

		internal string Title
		{
			get
			{
				return _Title ?? string.Empty;
			}
			set
			{
				_Title = value;
			}
		}

		internal string ResourceType
		{
			get
			{
				return _ResourceType ?? "StateInfo";
			}
			set
			{
				_ResourceType = value;
			}
		}

		internal string ResourceKey
		{
			get
			{
				return _ResourceKey ?? string.Empty;
			}
			set
			{
				_ResourceKey = value;
			}
		}

		internal IEnumerable<KeyValuePair<string, string>> Attributes
		{
			get
			{
				return _Attributes;
			}
		}

		protected FluentDialog(string key, IEnumerable<FluentState> states, FluentState initial)
		{
			Key = key;
			States = states;
			Initial = initial;
		}

		protected internal void AddAttribute(string key, string value)
		{
			if (string.IsNullOrEmpty(key))
				throw new ArgumentException("key");
			if (string.IsNullOrEmpty(value))
				throw new ArgumentException("value");
			_Attributes.Add(new KeyValuePair<string, string>(key, value));
		}
	}

	public class FluentDialog<TStates, TInitial> : FluentDialog
		where TStates : class
		where TInitial : FluentState
	{
		private TStates _States;

		private FluentStateInfo StateInfo
		{ 
			get;
			set;
		}

		internal FluentDialog(FluentStateInfo stateInfo, string key, TStates states, FluentState initial)
			: base(key, GetStates(states), initial)
		{
			StateInfo = stateInfo;
			_States = states;
		}

		private static IEnumerable<FluentState> GetStates(TStates states)
		{
			foreach (PropertyDescriptor stateProperty in TypeDescriptor.GetProperties(states))
			{
				var fluentState = (FluentState)stateProperty.GetValue(states);
				fluentState.Key = stateProperty.Name;
				yield return fluentState;
			}
		}

		public FluentDialog<TStates, TInitial> Transition(string key, Func<TStates, FluentState> from, Func<TStates, FluentState> to)
		{
			if (from == null)
				throw new ArgumentNullException("from");
			if (to == null)
				throw new ArgumentNullException("to");
			if (string.IsNullOrEmpty(key))
				throw new ArgumentException("key");
			from(_States).AddTransition(key, to(_States));
			return this;
		}

		public FluentDialog<UStates, UInitial> Dialog<UStates, UInitial>(string key, UStates states, Func<UStates, UInitial> initial)
			where UStates : class
			where UInitial : FluentState
		{
			return StateInfo.Dialog(key, states, initial);
		}

		public void Build()
		{
			StateInfo.Build();
		}
	}
}
