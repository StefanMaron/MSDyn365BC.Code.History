﻿// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

/// <summary>
/// Exposes functionality to check whether the system is initializing as well as an event to subscribed to in order to execute logic right after the system has initialized.
/// </summary>
codeunit 150 "System Initialization"
{
    Access = Public;
    SingleInstance = true;

    /// <summary>
    /// Checks whether the system initialization is currently in progress.
    /// </summary>
    /// <return>True, if the system initialization is in progress; false, otherwise</returns>
    procedure IsInProgress(): Boolean
    var
        SystemInitializationImpl: Codeunit "System Initialization Impl.";
    begin
        exit(SystemInitializationImpl.IsInProgress());
    end;

    /// <summary>
    /// Integration event for after the system initialization.
    /// Subscribe to this event in order to execute additional initialization steps.
    /// </summary>
    [IntegrationEvent(false, false)]
    internal procedure OnAfterInitialization()
    begin
    end;
}

