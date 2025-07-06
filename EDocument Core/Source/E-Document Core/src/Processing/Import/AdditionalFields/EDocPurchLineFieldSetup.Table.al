#if not CLEANSCHEMA29
// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.eServices.EDocument.Processing.Import;

table 6109 "EDoc. Purch. Line Field Setup"
{
    Access = Internal;
    ObsoleteReason = 'Replaced by "ED Purchase Line Field Setup"';
#if not CLEAN26
    ObsoleteState = Pending;
    ObsoleteTag = '26.0';
#else
    ObsoleteState = Removed;
    ObsoleteTag = '29.0';
#endif
    InherentEntitlements = RIMDX;
    InherentPermissions = RIMDX;
    ReplicateData = false;

    fields
    {
        field(1; "Field No."; Integer)
        {
            Caption = 'Field No.';
            DataClassification = SystemMetadata;
            Editable = false;
        }
    }
    keys
    {
        key(PK; "Field No.")
        {
            Clustered = true;
        }
    }
}
#endif