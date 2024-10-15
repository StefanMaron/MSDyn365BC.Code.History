// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.Currency;

#pragma warning disable AS0109
table 331 "Adjust Exchange Rate Buffer"
#pragma warning restore AS0109
{
    Caption = 'Adjust Exchange Rate Buffer';
    ReplicateData = false;
#if CLEAN21
    TableType = Temporary;
#else
    ObsoleteReason = 'This table will be marked as temporary. Make sure you are not using this table to store records.';
    ObsoleteState = Pending;
    ObsoleteTag = '21.0';
#endif

    fields
    {
        field(1; "Currency Code"; Code[10])
        {
            Caption = 'Currency Code';
            DataClassification = SystemMetadata;
            TableRelation = Currency;
        }
        field(2; "Posting Group"; Code[20])
        {
            Caption = 'Posting Group';
            DataClassification = SystemMetadata;
        }
        field(3; AdjBase; Decimal)
        {
            AutoFormatType = 1;
            Caption = 'AdjBase';
            DataClassification = SystemMetadata;
        }
        field(4; AdjBaseLCY; Decimal)
        {
            AutoFormatType = 1;
            Caption = 'AdjBaseLCY';
            DataClassification = SystemMetadata;
        }
        field(5; AdjAmount; Decimal)
        {
            AutoFormatType = 1;
            Caption = 'AdjAmount';
            DataClassification = SystemMetadata;
        }
        field(6; TotalGainsAmount; Decimal)
        {
            AutoFormatType = 1;
            Caption = 'TotalGainsAmount';
            DataClassification = SystemMetadata;
        }
        field(7; TotalLossesAmount; Decimal)
        {
            AutoFormatType = 1;
            Caption = 'TotalLossesAmount';
            DataClassification = SystemMetadata;
        }
        field(8; "Dimension Entry No."; Integer)
        {
            Caption = 'Dimension Entry No.';
            DataClassification = SystemMetadata;
        }
        field(9; "Posting Date"; Date)
        {
            Caption = 'Posting Date';
            DataClassification = SystemMetadata;
        }
        field(10; "IC Partner Code"; Code[20])
        {
            Caption = 'IC Partner Code';
            DataClassification = SystemMetadata;
        }
        field(11; Index; Integer)
        {
            Caption = 'Index';
            DataClassification = SystemMetadata;
        }
        field(11760; "Initial G/L Account No."; Code[20])
        {
            Caption = 'Initial G/L Account No.';
            DataClassification = SystemMetadata;
#if CLEAN21
            ObsoleteState = Removed;
            ObsoleteTag = '24.0';
#else
            ObsoleteState = Pending;
            ObsoleteTag = '21.0';
#endif
            ObsoleteReason = 'The field is not used anymore.';
        }
        field(11761; "Document Type"; Option)
        {
            Caption = 'Document Type';
            DataClassification = SystemMetadata;
            OptionCaption = ' ,Payment,Invoice,Credit Memo,Finance Charge Memo,Reminder,Refund,Advance';
            OptionMembers = " ",Payment,Invoice,"Credit Memo","Finance Charge Memo",Reminder,Refund,Advance;
            ObsoleteState = Removed;
            ObsoleteReason = 'Moved to Core Localization Pack for Czech.';
            ObsoleteTag = '21.0';
        }
        field(11762; "Document No."; Code[20])
        {
            Caption = 'Document No.';
            DataClassification = SystemMetadata;
            ObsoleteState = Removed;
            ObsoleteReason = 'Moved to Core Localization Pack for Czech.';
            ObsoleteTag = '21.0';
        }
        field(11763; "Entry No."; Integer)
        {
            Caption = 'Entry No.';
            DataClassification = SystemMetadata;
            ObsoleteState = Removed;
            ObsoleteReason = 'Field Entry No. will be removed and this field should not be used.';
            ObsoleteTag = '21.0';
        }
        field(31000; Advance; Boolean)
        {
            Caption = 'Advance';
            DataClassification = SystemMetadata;
#if CLEAN21
            ObsoleteState = Removed;
            ObsoleteTag = '24.0';
#else
            ObsoleteState = Pending;
            ObsoleteTag = '21.0';
#endif
            ObsoleteReason = 'The field is not used anymore.';
        }
    }

    keys
    {
#if CLEAN21
        key(Key1; "Currency Code", "Posting Group", "Dimension Entry No.", "Posting Date", "IC Partner Code")
#else
        key(Key1; "Currency Code", "Posting Group", "Dimension Entry No.", "Posting Date", "IC Partner Code", Advance, "Initial G/L Account No.")
#endif
        {
            Clustered = true;
#if not CLEAN21
            ObsoleteState = Pending;
            ObsoleteReason = 'The obsoleted fields will be removed from primary key.';
            ObsoleteTag = '21.0';
#endif
        }
    }

    fieldgroups
    {
    }

#if not CLEAN21
    [Obsolete('Use the Get function without the Advance and "Initial G/L Account No." parameters instead. These fields are obsolete and will be removed from primary key.', '21.0')]
    procedure Get(CurrencyCode: Code[10]; PostingGroup: Code[20]; DimensionEntryNo: Integer; PostingDate: Date; ICPartnerCode: Code[20]; Advance2: Boolean; InitialGLcAcountNo: Code[20]) Result: Boolean
    var
        TempAdjustExchangeRateBuffer: Record "Adjust Exchange Rate Buffer" temporary;
    begin
        TempAdjustExchangeRateBuffer.CopyFilters(Rec);
        Reset();
        SetRange("Currency Code", CurrencyCode);
        SetRange("Posting Group", PostingGroup);
        SetRange("Dimension Entry No.", DimensionEntryNo);
        SetRange("Posting Date", PostingDate);
        SetRange("IC Partner Code", ICPartnerCode);
        if Count() > 1 then begin
            SetRange(Advance, Advance2);
            SetRange("Initial G/L Account No.", InitialGLcAcountNo);
        end;
        Result := FindFirst();
        CopyFilters(TempAdjustExchangeRateBuffer);
    end;
#endif
}
