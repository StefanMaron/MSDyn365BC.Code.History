// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Service.Setup;

tableextension 11809 "Service Mgt. Setup CZ" extends "Service Mgt. Setup"
{
    fields
    {
        field(11765; "Posting Desc. Code"; Code[10])
        {
            Caption = 'Posting Desc. Code';
            DataClassification = CustomerContent;
            ObsoleteState = Removed;
            ObsoleteReason = 'The functionality of posting description will be removed and this field should not be used. (Obsolete::Removed in release 01.2021)';
            ObsoleteTag = '18.0';
        }
        field(11766; "Default VAT Date"; Option)
        {
            Caption = 'Default VAT Date';
            DataClassification = CustomerContent;
            OptionCaption = 'Posting Date,Document Date,Blank';
            OptionMembers = "Posting Date","Document Date",Blank;
            ObsoleteState = Removed;
            ObsoleteReason = 'Moved to Core Localization Pack for Czech.';
            ObsoleteTag = '20.0';
        }
        field(11767; "Allow Alter Cust. Post. Groups"; Boolean)
        {
            Caption = 'Allow Alter Cust. Post. Groups';
            DataClassification = CustomerContent;
            ObsoleteState = Removed;
            ObsoleteReason = 'Moved to Core Localization Pack for Czech.';
            ObsoleteTag = '21.0';
        }
        field(11772; "Reas.Cd. on Tax Corr.Doc.Mand."; Boolean)
        {
            Caption = 'Reas.Cd. on Tax Corr.Doc.Mand.';
            DataClassification = CustomerContent;
            ObsoleteState = Removed;
            ObsoleteReason = 'The functionality of Tax corrective documents for VAT will be removed and this field should not be used. (Obsolete::Removed in release 01.2021)';
            ObsoleteTag = '18.0';
        }
        field(11775; "Reason Code For Payment Disc."; Code[10])
        {
            Caption = 'Reason Code For Payment Disc.';
            DataClassification = CustomerContent;
            ObsoleteState = Removed;
            ObsoleteReason = 'The functionality of Tax corrective documents for VAT will be removed and this field should not be used. (Obsolete::Removed in release 01.2021)';
            ObsoleteTag = '18.0';
        }
        field(11777; "Credit Memo Confirmation"; Boolean)
        {
            Caption = 'Credit Memo Confirmation';
            DataClassification = CustomerContent;
            ObsoleteState = Removed;
            ObsoleteReason = 'The functionality of Postponing VAT on Sales Cr.Memo will be removed and this field should not be used. (Obsolete::Removed in release 01.2021)';
            ObsoleteTag = '18.0';
        }
    }
}