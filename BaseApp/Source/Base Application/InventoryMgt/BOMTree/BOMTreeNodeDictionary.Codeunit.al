// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

/// <summary>
/// This exposes a collection of the BOM Tree Node objects that are hashed against the key for those instances.
/// </summary>
codeunit 3675 "BOM Tree Node Dictionary"
{
    var
        InstanceDictionaryImpl: Codeunit "BOM Tree Node Dictionary Impl.";

    /// <summary>
    /// Adds an instance to the dictionary. The key is fetched from the GetKey() procedure of the Instance implementation.
    /// <param name="Instance">The instance to add.</param>
    /// <remarks>In case there is another instance with a key same as the one being added, an error shall be raised.</remarks>
    /// </summary>
    procedure Add(Instance: Codeunit "BOM Tree Node")
    begin
        InstanceDictionaryImpl.Add(Instance);
    end;

    [TryFunction]
    /// <summary>
    /// Adds an instance to the dictionary by calling the Add() procedure in a TryFunction.
    /// <param name="Instance">The instance to add.</param>
    /// </summary>
    procedure TryAdd(Instance: Codeunit "BOM Tree Node")
    begin
        InstanceDictionaryImpl.Add(Instance);
    end;

    /// <summary>
    /// Fetches the instance based on the given key.
    /// <param name="InstanceKey">The key given.</param>
    /// <param name="Found">The instance that was fetched.</param>
    /// </summary>
    procedure Get(InstanceKey: Text; var Found: Codeunit "BOM Tree Node")
    begin
        InstanceDictionaryImpl.Get(InstanceKey, Found);
    end;

    [TryFunction]
    /// <summary>
    /// Fetches the instance based on the given key by calling the Get() procedure in a TryFunction.
    /// <param name="InstanceKey">The key given.</param>
    /// <param name="Found">The instance that was fetched.</param>
    /// </summary>
    procedure TryGet(UniqueKey: Text; var Found: Codeunit "BOM Tree Node")
    begin
        InstanceDictionaryImpl.Get(UniqueKey, Found);
    end;

    /// <summary>
    /// Removes the instance from the dictionary that correponds to the given key.
    /// <param name="InstanceKey">The given key.</param>
    /// </summary>
    procedure Remove(InstanceKey: Text)
    begin
        InstanceDictionaryImpl.Remove(InstanceKey);
    end;

    /// <summary>
    /// Resets the internal variables that allow iterating through the items in the dictionary.
    /// <remarks>It is a good practice to call this before starting an iteration.</remarks>
    /// </summary>
    procedure ResetEnumerator()
    begin
        InstanceDictionaryImpl.ResetEnumerator();
    end;

    /// <summary>
    /// Advances the enumerator to the next element of the dictionary.
    /// </summary>
    procedure MoveNext(): Boolean
    begin
        exit(InstanceDictionaryImpl.MoveNext());
    end;

    /// <summary>
    /// Gets the element in the dictionary at the current position of the enumerator.
    /// <param name="Instance">The instance pointed at.</param>
    /// </summary>
    procedure GetCurrent(var Instance: Codeunit "BOM Tree Node")
    begin
        InstanceDictionaryImpl.GetCurrent(Instance);
    end;

    /// <summary>
    /// Gets the number of items in the dictionary.
    /// </summary>
    procedure Count(): Integer
    begin
        exit(InstanceDictionaryImpl.Count());
    end;
}
