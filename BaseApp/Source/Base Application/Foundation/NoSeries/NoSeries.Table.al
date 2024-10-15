// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace Microsoft.Foundation.NoSeries;

using Microsoft.Finance.VAT.Ledger;

table 308 "No. Series"
{
    Caption = 'No. Series';
    DataCaptionFields = "Code", Description;
    DrillDownPageID = "No. Series";
    LookupPageID = "No. Series";

    fields
    {
        field(1; "Code"; Code[20])
        {
            Caption = 'Code';
            NotBlank = true;
        }
        field(2; Description; Text[100])
        {
            Caption = 'Description';
        }
        field(3; "Default Nos."; Boolean)
        {
            Caption = 'Default Nos.';

            trigger OnValidate()
            var
                IsHandled: Boolean;
            begin
                IsHandled := false;
                OnBeforeValidateDefaultNos(Rec, IsHandled);
                if not IsHandled then
                    if ("Default Nos." = false) and (xRec."Default Nos." <> "Default Nos.") and ("Manual Nos." = false) then
                        Validate("Manual Nos.", true);
            end;
        }
        field(4; "Manual Nos."; Boolean)
        {
            Caption = 'Manual Nos.';

            trigger OnValidate()
            var
                IsHandled: Boolean;
            begin
                IsHandled := false;
                OnBeforeValidateManualNos(Rec, IsHandled);
                if not IsHandled then
                    if ("Manual Nos." = false) and (xRec."Manual Nos." <> "Manual Nos.") and ("Default Nos." = false) then
                        Validate("Default Nos.", true);
            end;
        }
        field(5; "Date Order"; Boolean)
        {
            Caption = 'Date Order';
        }
        field(12100; "No. Series Type"; Option)
        {
            Caption = 'No. Series Type';
            OptionCaption = 'Normal,Sales,Purchase';
            OptionMembers = Normal,Sales,Purchase;

            trigger OnValidate()
            var
                NoSeriesLine: Record "No. Series Line";
                NoSeriesLineSales: Record "No. Series Line Sales";
                NoSeriesLinePurchase: Record "No. Series Line Purchase";
            begin
                if "No. Series Type" <> xRec."No. Series Type" then begin
                    case xRec."No. Series Type" of
                        "No. Series Type"::Normal:
                            begin
                                NoSeriesLine.SetRange("Series Code", Code);
                                RecordsFound := not NoSeriesLine.IsEmpty();
                            end;
                        "No. Series Type"::Sales:
                            begin
                                NoSeriesLineSales.SetRange("Series Code", Code);
                                RecordsFound := not NoSeriesLineSales.IsEmpty();
                            end;
                        "No. Series Type"::Purchase:
                            begin
                                NoSeriesLinePurchase.SetRange("Series Code", Code);
                                RecordsFound := not NoSeriesLinePurchase.IsEmpty();
                            end;
                    end;

                    if RecordsFound then
                        Error(Text1130004, FieldCaption("No. Series Type"));
                end;
            end;
        }
        field(12101; "VAT Register"; Code[10])
        {
            Caption = 'VAT Register';
            TableRelation = if ("No. Series Type" = CONST(Sales)) "VAT Register" where(Type = CONST(Sale))
            else
            IF ("No. Series Type" = CONST(Purchase)) "VAT Register" where(Type = CONST(Purchase));

            trigger OnValidate()
            begin
                if "No. Series Type" = "No. Series Type"::Normal then
                    Error(Text1130000, FieldCaption("No. Series Type"));
            end;
        }
        field(12102; "VAT Reg. Print Priority"; Integer)
        {
            Caption = 'VAT Reg. Print Priority';
        }
        field(12103; "Reverse Sales VAT No. Series"; Code[20])
        {
            Caption = 'Reverse Sales VAT No. Series';
            TableRelation = if ("No. Series Type" = CONST(Sales)) "No. Series" where("No. Series Type" = CONST(Purchase))
            else
            IF ("No. Series Type" = CONST(Purchase)) "No. Series" where("No. Series Type" = CONST(Sales));

            trigger OnValidate()
            begin
                if "No. Series Type" = "No. Series Type"::Normal then
                    Error(Text1130000, FieldCaption("No. Series Type"));
            end;
        }
    }

    keys
    {
        key(Key1; "Code")
        {
            Clustered = true;
        }
        key(Key2; "VAT Reg. Print Priority")
        {
        }
    }

    fieldgroups
    {
        fieldgroup(DropDown; Code, Description)
        {
        }
    }

    trigger OnDelete()
    var
        NoSeriesLine: Record "No. Series Line";
        NoSeriesRelationship: Record "No. Series Relationship";
        NoSeriesLineSales: Record "No. Series Line Sales";
        NoSeriesLinePurchase: Record "No. Series Line Purchase";
    begin
        NoSeriesLine.SetRange("Series Code", Code);
        NoSeriesLine.DeleteAll();

        NoSeriesLineSales.SetRange("Series Code", Code);
        NoSeriesLineSales.DeleteAll();

        NoSeriesLinePurchase.SetRange("Series Code", Code);
        NoSeriesLinePurchase.DeleteAll();

        NoSeriesRelationship.SetRange(Code, Code);
        NoSeriesRelationship.DeleteAll();
        NoSeriesRelationship.SetRange(Code);

        NoSeriesRelationship.SetRange("Series Code", Code);
        NoSeriesRelationship.DeleteAll();
        NoSeriesRelationship.SetRange("Series Code");
    end;

    var
        RecordsFound: Boolean;
        Text1130000: Label '%1 must not be Normal';
        Text1130004: Label 'No. Serie Lines must be deleted before changing the %1';

    procedure DrillDown()
    var
        NoSeriesLine: Record "No. Series Line";
        NoSeriesLineSales: Record "No. Series Line Sales";
        NoSeriesLinePurchase: Record "No. Series Line Purchase";
    begin
        case "No. Series Type" of
            "No. Series Type"::Normal:
                begin
                    FindNoSeriesLineToShow(NoSeriesLine);
                    if NoSeriesLine.Find('-') then;
                    NoSeriesLine.SetRange("Starting Date");
                    NoSeriesLine.SetRange(Open);
                    PAGE.RunModal(0, NoSeriesLine);
                end;
            "No. Series Type"::Sales:
                begin
                    FindNoSeriesLineSalesToShow(NoSeriesLineSales);
                    if NoSeriesLineSales.Find('-') then;
                    NoSeriesLineSales.SetRange("Starting Date");
                    NoSeriesLineSales.SetRange(Open);
                    PAGE.RunModal(0, NoSeriesLineSales);
                end;
            "No. Series Type"::Purchase:
                begin
                    FindNoSeriesLinePurchToShow(NoSeriesLinePurchase);
                    if NoSeriesLinePurchase.Find('-') then;
                    NoSeriesLinePurchase.SetRange("Starting Date");
                    NoSeriesLinePurchase.SetRange(Open);
                    PAGE.RunModal(0, NoSeriesLinePurchase);
                end;
        end;
    end;

    procedure UpdateLine(var StartDate: Date; var StartNo: Code[20]; var EndNo: Code[20]; var LastNoUsed: Code[20]; var WarningNo: Code[20]; var IncrementByNo: Integer; var LastDateUsed: Date)
    var
        AllowGaps: Boolean;
    begin
        UpdateLine(StartDate, StartNo, EndNo, LastNoUsed, WarningNo, IncrementByNo, LastDateUsed, AllowGaps);
    end;

    procedure UpdateLine(var StartDate: Date; var StartNo: Code[20]; var EndNo: Code[20]; var LastNoUsed: Code[20]; var WarningNo: Code[20]; var IncrementByNo: Integer; var LastDateUsed: Date; var AllowGaps: Boolean)
    var
        NoSeriesLine: Record "No. Series Line";
        NoSeriesLineSales: Record "No. Series Line Sales";
        NoSeriesLinePurchase: Record "No. Series Line Purchase";
    begin
        case "No. Series Type" of
            "No. Series Type"::Normal:
                begin
                    FindNoSeriesLineToShow(NoSeriesLine);
                    if not NoSeriesLine.Find('-') then
                        NoSeriesLine.Init();
                    StartDate := NoSeriesLine."Starting Date";
                    StartNo := NoSeriesLine."Starting No.";
                    EndNo := NoSeriesLine."Ending No.";
                    LastNoUsed := NoSeriesLine.GetLastNoUsed();
                    WarningNo := NoSeriesLine."Warning No.";
                    IncrementByNo := NoSeriesLine."Increment-by No.";
                    LastDateUsed := NoSeriesLine."Last Date Used";
                    AllowGaps := NoSeriesLine."Allow Gaps in Nos.";
                end;
            "No. Series Type"::Sales:
                begin
                    FindNoSeriesLineSalesToShow(NoSeriesLineSales);
                    if not NoSeriesLineSales.Find('-') then
                        NoSeriesLineSales.Init();
                    StartDate := NoSeriesLineSales."Starting Date";
                    StartNo := NoSeriesLineSales."Starting No.";
                    EndNo := NoSeriesLineSales."Ending No.";
                    LastNoUsed := NoSeriesLineSales."Last No. Used";
                    WarningNo := NoSeriesLineSales."Warning No.";
                    IncrementByNo := NoSeriesLineSales."Increment-by No.";
                    LastDateUsed := NoSeriesLineSales."Last Date Used"
                end;
            "No. Series Type"::Purchase:
                begin
                    FindNoSeriesLinePurchToShow(NoSeriesLinePurchase);
                    if not NoSeriesLinePurchase.Find('-') then
                        NoSeriesLinePurchase.Init();
                    StartDate := NoSeriesLinePurchase."Starting Date";
                    StartNo := NoSeriesLinePurchase."Starting No.";
                    EndNo := NoSeriesLinePurchase."Ending No.";
                    LastNoUsed := NoSeriesLinePurchase."Last No. Used";
                    WarningNo := NoSeriesLinePurchase."Warning No.";
                    IncrementByNo := NoSeriesLinePurchase."Increment-by No.";
                    LastDateUsed := NoSeriesLinePurchase."Last Date Used"
                end;
        end;
    end;

    procedure FindNoSeriesLineToShow(var NoSeriesLine: Record "No. Series Line")
    var
        NoSeriesManagement: Codeunit NoSeriesManagement;
    begin
        NoSeriesManagement.SetNoSeriesLineFilter(NoSeriesLine, Code, 0D);

        if NoSeriesLine.FindLast() then
            exit;

        NoSeriesLine.Reset();
        NoSeriesLine.SetRange("Series Code", Code);
    end;

    local procedure FindNoSeriesLineSalesToShow(var NoSeriesLineSales: Record "No. Series Line Sales")
    var
        NoSeriesMgt: Codeunit NoSeriesManagement;
    begin
        NoSeriesMgt.SetNoSeriesLineSalesFilter(NoSeriesLineSales, Code, 0D);

        if NoSeriesLineSales.FindLast() then
            exit;

        NoSeriesLineSales.Reset();
        NoSeriesLineSales.SetRange("Series Code", Code);
    end;

    local procedure FindNoSeriesLinePurchToShow(var NoSeriesLinePurchase: Record "No. Series Line Purchase")
    var
        NoSeriesMgt: Codeunit NoSeriesManagement;
    begin
        NoSeriesMgt.SetNoSeriesLinePurchaseFilter(NoSeriesLinePurchase, Code, 0D);

        if NoSeriesLinePurchase.FindLast() then
            exit;

        NoSeriesLinePurchase.Reset();
        NoSeriesLinePurchase.SetRange("Series Code", Code);
    end;

    internal procedure SetAllowGaps(AllowGaps: Boolean)
    var
        NoSeriesLine: Record "No. Series Line";
        StartDate: Date;
    begin
        FindNoSeriesLineToShow(NoSeriesLine);
        StartDate := NoSeriesLine."Starting Date";
        NoSeriesLine.SetRange("Allow Gaps in Nos.", not AllowGaps);
        NoSeriesLine.SetFilter("Starting Date", '>=%1', StartDate);
        NoSeriesLine.LockTable();
        if NoSeriesLine.FindSet() then
            repeat
                NoSeriesLine.Validate("Allow Gaps in Nos.", AllowGaps);
                NoSeriesLine.Modify();
            until NoSeriesLine.Next() = 0;
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeValidateDefaultNos(var NoSeries: Record "No. Series"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeValidateManualNos(var NoSeries: Record "No. Series"; var IsHandled: Boolean)
    begin
    end;
}

