// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace Microsoft.Foundation.NoSeries;

/// <summary>
/// This codeunit verifies that a number can be retrieved for the given No. Series.
/// </summary>
codeunit 4143 "No. Series Check"
{
    TableNo = "No. Series";
#if not CLEAN24
    Access = Public;
    ObsoleteReason = 'Please use the PeekNextNo procedure from the  "No. Series" codeunit instead';
    ObsoleteState = Pending;
    ObsoleteTag = '24.0';
#else
    Access = Internal;
#endif

    trigger OnRun()
    var
        NoSeries: Codeunit "No. Series";
    begin
        NoSeries.PeekNextNo(Rec.Code, WorkDate());
    end;
}