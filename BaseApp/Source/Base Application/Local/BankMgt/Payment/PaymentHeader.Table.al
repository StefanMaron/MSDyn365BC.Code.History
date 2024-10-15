﻿// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Bank.Payment;

using Microsoft.Bank.BankAccount;
using Microsoft.Finance.GeneralLedger.Journal;
using Microsoft.Finance.Currency;
using Microsoft.Finance.Dimension;
using Microsoft.Finance.GeneralLedger.Account;
using Microsoft.FixedAssets.FixedAsset;
using Microsoft.Foundation.Address;
using Microsoft.Foundation.AuditCodes;
using Microsoft.Foundation.Company;
using Microsoft.Foundation.Enums;
using Microsoft.Foundation.NoSeries;
using Microsoft.Purchases.Vendor;
using Microsoft.Sales.Customer;

table 10865 "Payment Header"
{
    Caption = 'Payment Header';
    DrillDownPageID = "Payment Slip List";
    LookupPageID = "Payment Slip List";

    fields
    {
        field(1; "No."; Code[20])
        {
            Caption = 'No.';
            Editable = false;

            trigger OnValidate()
            begin
                if "No." <> xRec."No." then begin
                    PaymentClass := PaymentClass2;
                    NoSeriesManagement.TestManual(PaymentClass."Header No. Series");
                    "No. Series" := '';
                end;
            end;
        }
        field(2; "Currency Code"; Code[10])
        {
            Caption = 'Currency Code';
            TableRelation = Currency;

            trigger OnValidate()
            var
                PaymentLine: Record "Payment Line";
                CompanyBank: Record "Bank Account";
            begin
                if "Account Type" = "Account Type"::"Bank Account" then
                    if CompanyBank.Get("Account No.") then
                        if CompanyBank."Currency Code" <> '' then
                            Error(Text008, CompanyBank."Currency Code");

                if CurrFieldNo <> FieldNo("Currency Code") then
                    UpdateCurrencyFactor()
                else
                    if "Currency Code" <> xRec."Currency Code" then begin
                        PaymentLine.SetRange("No.", "No.");
                        if PaymentLine.FindFirst() then
                            Error(Text002);
                        UpdateCurrencyFactor();
                    end else
                        if "Currency Code" <> '' then begin
                            UpdateCurrencyFactor();
                            if "Currency Factor" <> xRec."Currency Factor" then
                                ConfirmUpdateCurrencyFactor();
                        end;
                if "Currency Code" <> xRec."Currency Code" then begin
                    PaymentLine.Init();
                    PaymentLine.SetRange("No.", "No.");
                    PaymentLine.ModifyAll("Currency Code", "Currency Code");
                    PaymentLine.ModifyAll("Currency Factor", "Currency Factor");
                end;
            end;
        }
        field(3; "Currency Factor"; Decimal)
        {
            Caption = 'Currency Factor';
            DecimalPlaces = 0 : 15;

            trigger OnValidate()
            var
                PaymentLine: Record "Payment Line";
            begin
                PaymentLine.SetRange("No.", "No.");
                if PaymentLine.FindSet() then
                    repeat
                        PaymentLine."Currency Factor" := "Currency Factor";
                        PaymentLine.Validate(Amount);
                        PaymentLine.Modify();
                    until PaymentLine.Next() = 0;
            end;
        }
        field(4; "Posting Date"; Date)
        {
            Caption = 'Posting Date';

            trigger OnValidate()
            var
                PaymentLine: Record "Payment Line";
            begin
                if "Posting Date" <> xRec."Posting Date" then begin
                    PaymentLine.Reset();
                    PaymentLine.SetRange("No.", "No.");
                    PaymentLine.ModifyAll("Posting Date", "Posting Date");
                end;
            end;
        }
        field(5; "Document Date"; Date)
        {
            Caption = 'Document Date';

            trigger OnValidate()
            var
                PaymentLine: Record "Payment Line";
            begin
                if "Document Date" <> xRec."Document Date" then begin
                    PaymentLine.Reset();
                    PaymentLine.SetRange("No.", "No.");
                    if PaymentLine.FindSet() then
                        repeat
                            PaymentLine.UpdateDueDate("Document Date");
                        until PaymentLine.Next() = 0;
                end;
            end;
        }
        field(6; "Payment Class"; Text[30])
        {
            Caption = 'Payment Class';
            TableRelation = "Payment Class";

            trigger OnValidate()
            begin
                Validate("Status No.");
            end;
        }
        field(7; "Status No."; Integer)
        {
            Caption = 'Status No.';
            TableRelation = "Payment Status".Line where("Payment Class" = field("Payment Class"));

            trigger OnValidate()
            var
                PaymentStep: Record "Payment Step";
                PaymentStatus: Record "Payment Status";
            begin
                PaymentStep.SetRange("Payment Class", "Payment Class");
                PaymentStep.SetFilter("Next Status", '>%1', "Status No.");
                PaymentStep.SetRange("Action Type", PaymentStep."Action Type"::Ledger);
                if PaymentStep.FindFirst() then
                    "Source Code" := PaymentStep."Source Code";
                PaymentStatus.Get("Payment Class", "Status No.");
                "Archiving Authorized" := PaymentStatus."Archiving Authorized";
            end;
        }
        field(8; "Status Name"; Text[50])
        {
            CalcFormula = Lookup("Payment Status".Name where("Payment Class" = field("Payment Class"),
                                                              Line = field("Status No.")));
            Caption = 'Status Name';
            Editable = false;
            FieldClass = FlowField;
        }
        field(9; "Shortcut Dimension 1 Code"; Code[20])
        {
            CaptionClass = '1,2,1';
            Caption = 'Shortcut Dimension 1 Code';

            trigger OnLookup()
            begin
                LookupShortcutDimCode(1, "Shortcut Dimension 1 Code");
                Validate("Shortcut Dimension 1 Code");
            end;

            trigger OnValidate()
            begin
                ValidateShortcutDimCode(1, "Shortcut Dimension 1 Code");
                Modify();
            end;
        }
        field(10; "Shortcut Dimension 2 Code"; Code[20])
        {
            CaptionClass = '1,2,2';
            Caption = 'Shortcut Dimension 2 Code';

            trigger OnLookup()
            begin
                LookupShortcutDimCode(2, "Shortcut Dimension 2 Code");
                Validate("Shortcut Dimension 2 Code");
            end;

            trigger OnValidate()
            begin
                ValidateShortcutDimCode(2, "Shortcut Dimension 2 Code");
                Modify();
            end;
        }
        field(11; "Payment Class Name"; Text[50])
        {
            CalcFormula = Lookup("Payment Class".Name where(Code = field("Payment Class")));
            Caption = 'Payment Class Name';
            Editable = false;
            FieldClass = FlowField;
        }
        field(12; "No. Series"; Code[20])
        {
            Caption = 'No. Series';
            TableRelation = "No. Series";
        }
        field(13; "Source Code"; Code[10])
        {
            Caption = 'Source Code';
            TableRelation = "Source Code";
        }
        field(14; "Account Type"; enum "Gen. Journal Account Type")
        {
            Caption = 'Account Type';

            trigger OnValidate()
            begin
                if "Account Type" <> xRec."Account Type" then begin
                    Validate("Account No.", '');
                    "Dimension Set ID" := 0;
                    DimensionManagement.UpdateGlobalDimFromDimSetID("Dimension Set ID", "Shortcut Dimension 1 Code",
                      "Shortcut Dimension 2 Code");
                end;
            end;
        }
        field(15; "Account No."; Code[20])
        {
            Caption = 'Account No.';
            TableRelation = if ("Account Type" = const("G/L Account")) "G/L Account"
            else
            if ("Account Type" = const(Customer)) Customer
            else
            if ("Account Type" = const(Vendor)) Vendor
            else
            if ("Account Type" = const("Bank Account")) "Bank Account"
            else
            if ("Account Type" = const("Fixed Asset")) "Fixed Asset";

            trigger OnValidate()
            begin
                if "Account No." <> xRec."Account No." then begin
                    "Dimension Set ID" := 0;
                    DimensionManagement.UpdateGlobalDimFromDimSetID("Dimension Set ID", "Shortcut Dimension 1 Code",
                      "Shortcut Dimension 2 Code");
                    if "Account No." <> '' then
                        DimensionSetup();
                end;
                if "Account Type" = "Account Type"::"Bank Account" then begin
                    if CompanyBankAccount.Get("Account No.") then begin
                        if "Currency Code" = '' then
                            if CompanyBankAccount."Currency Code" <> '' then
                                Error(Text006);
                        if "Currency Code" <> '' then
                            if (CompanyBankAccount."Currency Code" <> "Currency Code") and (CompanyBankAccount."Currency Code" <> '') then
                                Error(Text007, "Currency Code");
                        "Bank Branch No." := CompanyBankAccount."Bank Branch No.";
                        "Bank Account No." := CompanyBankAccount."Bank Account No.";
                        IBAN := CompanyBankAccount.IBAN;
                        "SWIFT Code" := CompanyBankAccount."SWIFT Code";
                        "Bank Country/Region Code" := CompanyBankAccount."Country/Region Code";
                        "Agency Code" := CompanyBankAccount."Agency Code";
                        "RIB Key" := CompanyBankAccount."RIB Key";
                        "RIB Checked" := CompanyBankAccount."RIB Checked";
                        "Bank Name" := CompanyBankAccount.Name;
                        "Bank Post Code" := CompanyBankAccount."Post Code";
                        "Bank City" := CompanyBankAccount.City;
                        "Bank Name 2" := CompanyBankAccount."Name 2";
                        "Bank Address" := CompanyBankAccount.Address;
                        "Bank Address 2" := CompanyBankAccount."Address 2";
                        "National Issuer No." := CompanyBankAccount."National Issuer No.";
                    end else
                        InitBankAccount();
                end else
                    InitBankAccount();
            end;
        }
        field(16; "Amount (LCY)"; Decimal)
        {
            CalcFormula = sum("Payment Line"."Amount (LCY)" where("No." = field("No.")));
            Caption = 'Amount (LCY)';
            Editable = false;
            FieldClass = FlowField;
        }
        field(17; Amount; Decimal)
        {
            CalcFormula = sum("Payment Line".Amount where("No." = field("No.")));
            Caption = 'Amount';
            Editable = false;
            FieldClass = FlowField;
        }
        field(18; "Bank Branch No."; Text[20])
        {
            Caption = 'Bank Branch No.';

            trigger OnValidate()
            begin
                "RIB Checked" := RibKey.Check("Bank Branch No.", "Agency Code", "Bank Account No.", "RIB Key");
            end;
        }
        field(19; "Bank Account No."; Text[30])
        {
            Caption = 'Bank Account No.';

            trigger OnValidate()
            begin
                "RIB Checked" := RibKey.Check("Bank Branch No.", "Agency Code", "Bank Account No.", "RIB Key");
            end;
        }
        field(20; "Agency Code"; Text[20])
        {
            Caption = 'Agency Code';

            trigger OnValidate()
            begin
                "RIB Checked" := RibKey.Check("Bank Branch No.", "Agency Code", "Bank Account No.", "RIB Key");
            end;
        }
        field(21; "RIB Key"; Integer)
        {
            Caption = 'RIB Key';

            trigger OnValidate()
            begin
                "RIB Checked" := RibKey.Check("Bank Branch No.", "Agency Code", "Bank Account No.", "RIB Key");
            end;
        }
        field(22; "RIB Checked"; Boolean)
        {
            Caption = 'RIB Checked';
            Editable = false;
        }
        field(23; "Bank Name"; Text[100])
        {
            Caption = 'Bank Name';
        }
        field(24; "Bank Post Code"; Code[20])
        {
            Caption = 'Bank Post Code';
            TableRelation = if ("Bank Country/Region Code" = const('')) "Post Code"
            else
            if ("Bank Country/Region Code" = filter(<> '')) "Post Code" where("Country/Region Code" = field("Bank Country/Region Code"));
            ValidateTableRelation = false;

            trigger OnValidate()
            begin
                PostCode.ValidatePostCode(
                  "Bank City", "Bank Post Code", "Bank County", "Bank Country/Region Code", (CurrFieldNo <> 0) and GuiAllowed);
            end;
        }
        field(25; "Bank City"; Text[30])
        {
            Caption = 'Bank City';
            TableRelation = if ("Bank Country/Region Code" = const('')) "Post Code".City
            else
            if ("Bank Country/Region Code" = filter(<> '')) "Post Code".City where("Country/Region Code" = field("Bank Country/Region Code"));
            ValidateTableRelation = false;

            trigger OnValidate()
            begin
                PostCode.ValidatePostCode(
                  "Bank City", "Bank Post Code", "Bank County", "Bank Country/Region Code", (CurrFieldNo <> 0) and GuiAllowed);
            end;
        }
        field(26; "Bank Name 2"; Text[50])
        {
            Caption = 'Bank Name 2';
        }
        field(27; "Bank Address"; Text[100])
        {
            Caption = 'Bank Address';
        }
        field(28; "Bank Address 2"; Text[50])
        {
            Caption = 'Bank Address 2';
        }
        field(29; "Bank Contact"; Text[100])
        {
            Caption = 'Bank Contact';
        }
        field(30; "Bank County"; Text[30])
        {
            Caption = 'Bank County';
        }
        field(31; "Bank Country/Region Code"; Code[10])
        {
            Caption = 'Bank Country/Region Code';
            TableRelation = "Country/Region";
        }
        field(32; "National Issuer No."; Code[6])
        {
            Caption = 'National Issuer No.';
            Numeric = true;
        }
        field(40; "File Export Completed"; Boolean)
        {
            Caption = 'File Export Completed';
            Editable = false;
        }
        field(41; "No. of Lines"; Integer)
        {
            CalcFormula = count("Payment Line" where("No." = field("No.")));
            Caption = 'No. of Lines';
            Editable = false;
            FieldClass = FlowField;
        }
        field(42; "No. of Unposted Lines"; Integer)
        {
            CalcFormula = count("Payment Line" where("No." = field("No."),
                                                      Posted = const(false)));
            Caption = 'No. of Unposted Lines';
            Editable = false;
            FieldClass = FlowField;
        }
        field(43; "Archiving Authorized"; Boolean)
        {
            CalcFormula = Lookup("Payment Status"."Archiving Authorized" where("Payment Class" = field("Payment Class"),
                                                                                Line = field("Status No.")));
            Caption = 'Archiving Authorized';
            Editable = false;
            FieldClass = FlowField;
        }
        field(50; IBAN; Code[50])
        {
            Caption = 'IBAN';

            trigger OnValidate()
            var
                CompanyInfo: Record "Company Information";
            begin
                CompanyInfo.CheckIBAN(IBAN);
            end;
        }
        field(51; "SWIFT Code"; Code[20])
        {
            Caption = 'SWIFT Code';
        }
        field(132; "Partner Type"; Enum "Partner Type")
        {
            Caption = 'Partner Type';
        }
        field(480; "Dimension Set ID"; Integer)
        {
            Caption = 'Dimension Set ID';
            Editable = false;
            TableRelation = "Dimension Set Entry";

            trigger OnLookup()
            begin
                Rec.ShowDocDim();
            end;

            trigger OnValidate()
            begin
                DimensionManagement.UpdateGlobalDimFromDimSetID("Dimension Set ID", "Shortcut Dimension 1 Code", "Shortcut Dimension 2 Code");
            end;
        }
    }

    keys
    {
        key(Key1; "No.")
        {
            Clustered = true;
        }
        key(Key2; "Posting Date")
        {
        }
    }

    fieldgroups
    {
        fieldgroup(DropDown; "No.")
        {
        }
    }

    trigger OnDelete()
    var
        PaymentLine: Record "Payment Line";
    begin
        if "Status No." > 0 then
            Error(Text000);

        PaymentLine.SetRange("No.", "No.");
        PaymentLine.SetFilter("Copied To No.", '<>''''');
        if PaymentLine.FindFirst() then
            Error(Text000);
        PaymentLine.SetRange("Copied To No.");
        PaymentLine.DeleteAll(true);
    end;

    trigger OnInsert()
    begin
        if "No." = '' then begin
            if PAGE.RunModal(PAGE::"Payment Class List", PaymentClass2) = ACTION::LookupOK then
                PaymentClass := PaymentClass2;
            PaymentClass.TestField("Header No. Series");
            NoSeriesManagement.InitSeries(PaymentClass."Header No. Series", xRec."No. Series", 0D, "No.", "No. Series");
            Validate("Payment Class", PaymentClass.Code);
        end;
        InitHeader();
    end;

    var
        PaymentClass: Record "Payment Class";
        PaymentHeader: Record "Payment Header";
        PaymentClass2: Record "Payment Class";
        CurrencyExchangeRate: Record "Currency Exchange Rate";
        CompanyBankAccount: Record "Bank Account";
        PostCode: Record "Post Code";
        DimensionManagement: Codeunit DimensionManagement;
        NoSeriesManagement: Codeunit NoSeriesManagement;
        RibKey: Codeunit "RIB Key";
        CurrencyDate: Date;

        Text000: Label 'Deleting the line is not allowed.';
        Text001: Label 'There is no line to treat.';
        Text002: Label 'You cannot modify Currency Code because the Payment Header contains lines.';
        Text006: Label 'The currency code for the document is the LCY Code.\\Please select a bank for which the currency code is the LCY Code.';
        Text007: Label 'The currency code for the document is %1.\\Please select a bank for which the currency code is %1 or the LCY Code.';
        Text008: Label 'Your bank''s currency code is %1.\\You must change the bank account code before modifying the currency code.';
        Text009: Label 'You may have changed a dimension.\\Do you want to update the lines?';

    [Scope('OnPrem')]
    procedure LookupShortcutDimCode(FieldNo: Integer; var ShortcutDimCode: Code[20])
    begin
        DimensionManagement.LookupDimValueCode(FieldNo, ShortcutDimCode);
        DimensionManagement.ValidateShortcutDimValues(FieldNo, ShortcutDimCode, "Dimension Set ID");
    end;

    [Scope('OnPrem')]
    procedure ValidateShortcutDimCode(FieldNo: Integer; var ShortcutDimCode: Code[20])
    begin
        DimensionManagement.ValidateShortcutDimValues(FieldNo, ShortcutDimCode, "Dimension Set ID");
        if xRec."Dimension Set ID" <> "Dimension Set ID" then
            if PaymentLinesExist() then
                UpdateAllLineDim("Dimension Set ID", xRec."Dimension Set ID");
    end;

    [Scope('OnPrem')]
    procedure AssistEdit(OldPaymentHeader: Record "Payment Header"): Boolean
    begin
        with PaymentHeader do begin
            PaymentHeader := Rec;
            PaymentClass := PaymentClass2;

            PaymentClass.TestField("Header No. Series");
            if NoSeriesManagement.SelectSeries(PaymentClass."Header No. Series", OldPaymentHeader."No. Series", "No. Series") then begin
                PaymentClass := PaymentClass2;
                PaymentClass.TestField("Header No. Series");
                NoSeriesManagement.SetSeries("No.");
                Rec := PaymentHeader;
                exit(true);
            end;
        end;
    end;

    local procedure UpdateCurrencyFactor()
    begin
        if "Currency Code" <> '' then begin
            CurrencyDate := WorkDate();
            "Currency Factor" := CurrencyExchangeRate.ExchangeRate(CurrencyDate, "Currency Code");
        end else
            "Currency Factor" := 1;
    end;

    local procedure ConfirmUpdateCurrencyFactor()
    begin
        "Currency Factor" := xRec."Currency Factor";
    end;

    [Scope('OnPrem')]
    procedure InitBankAccount()
    begin
        "Bank Branch No." := '';
        "Bank Account No." := '';
        IBAN := '';
        "SWIFT Code" := '';
        "Agency Code" := '';
        "RIB Key" := 0;
        "RIB Checked" := false;
        "Bank Name" := '';
        "Bank Post Code" := '';
        "Bank City" := '';
        "Bank Name 2" := '';
        "Bank Address" := '';
        "Bank Address 2" := '';
        "Bank Contact" := '';
        "Bank County" := '';
        "Bank Country/Region Code" := '';
        "National Issuer No." := '';
    end;

    [Scope('OnPrem')]
    procedure TestNbOfLines()
    begin
        CalcFields("No. of Lines");
        if "No. of Lines" = 0 then
            Error(Text001);
    end;

    [Scope('OnPrem')]
    procedure InitHeader()
    begin
        "Posting Date" := WorkDate();
        "Document Date" := WorkDate();
        Validate("Account Type", "Account Type"::"Bank Account");
    end;

    [Scope('OnPrem')]
    procedure DimensionSetup()
    begin
        DimensionCreate();
    end;

    [Scope('OnPrem')]
    procedure DimensionCreate()
    var
        DefaultDimSource: List of [Dictionary of [Integer, Code[20]]];
        OldDimSetID: Integer;
    begin
        DimensionManagement.AddDimSource(DefaultDimSource, DimensionManagement.TypeToTableID1("Account Type".AsInteger()), Rec."Account No.");
        "Shortcut Dimension 1 Code" := '';
        "Shortcut Dimension 2 Code" := '';
        OldDimSetID := "Dimension Set ID";

        "Dimension Set ID" :=
          DimensionManagement.GetRecDefaultDimID(
            Rec, CurrFieldNo, DefaultDimSource, "Source Code", "Shortcut Dimension 1 Code", "Shortcut Dimension 2 Code", 0, 0);

        if OldDimSetID <> "Dimension Set ID" then begin
            Modify();
            if PaymentLinesExist() then
                UpdateAllLineDim("Dimension Set ID", OldDimSetID);
        end;
    end;

    [Scope('OnPrem')]
    procedure ShowDocDim()
    var
        OldDimSetID: Integer;
    begin
        OldDimSetID := "Dimension Set ID";
        "Dimension Set ID" :=
          DimensionManagement.EditDimensionSet(
            "Dimension Set ID", StrSubstNo('%1 %2', 'Payment: ', "No."),
            "Shortcut Dimension 1 Code", "Shortcut Dimension 2 Code");

        if OldDimSetID <> "Dimension Set ID" then begin
            Modify();
            if PaymentLinesExist() then
                UpdateAllLineDim("Dimension Set ID", OldDimSetID);
        end;
    end;

    [Scope('OnPrem')]
    procedure PaymentLinesExist(): Boolean
    var
        PaymentLine: Record "Payment Line";
    begin
        PaymentLine.Reset();
        PaymentLine.SetRange("No.", "No.");
        exit(not PaymentLine.IsEmpty())
    end;

    local procedure UpdateAllLineDim(NewParentDimSetID: Integer; OldParentDimSetID: Integer)
    var
        PaymentLine: Record "Payment Line";
        NewDimSetID: Integer;
    begin
        // Update all lines with changed dimensions.

        if NewParentDimSetID = OldParentDimSetID then
            exit;
        if not Confirm(Text009) then
            exit;

        PaymentLine.Reset();
        PaymentLine.SetRange("No.", "No.");
        PaymentLine.LockTable();
        if PaymentLine.Find('-') then
            repeat
                NewDimSetID := DimensionManagement.GetDeltaDimSetID(PaymentLine."Dimension Set ID", NewParentDimSetID, OldParentDimSetID);
                if PaymentLine."Dimension Set ID" <> NewDimSetID then begin
                    PaymentLine."Dimension Set ID" := NewDimSetID;
                    PaymentLine.Modify();
                end;
            until PaymentLine.Next() = 0;
    end;
}

