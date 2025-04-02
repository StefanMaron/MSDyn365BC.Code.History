// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.VAT.Reporting;

using Microsoft.Finance.GeneralLedger.Account;
using Microsoft.Finance.GeneralLedger.Journal;
using Microsoft.Finance.SalesTax;
using Microsoft.Finance.VAT.Ledger;
using Microsoft.Finance.VAT.Setup;
using Microsoft.Utilities;

table 256 "VAT Statement Line"
{
    Caption = 'VAT Statement Line';
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Statement Template Name"; Code[10])
        {
            Caption = 'Statement Template Name';
            TableRelation = "VAT Statement Template";
        }
        field(2; "Statement Name"; Code[10])
        {
            Caption = 'Statement Name';
            TableRelation = "VAT Statement Name".Name where("Statement Template Name" = field("Statement Template Name"));
        }
        field(3; "Line No."; Integer)
        {
            Caption = 'Line No.';
        }
        field(4; "Row No."; Code[10])
        {
            Caption = 'Row No.';
        }
        field(5; Description; Text[100])
        {
            Caption = 'Description';
        }
        field(6; Type; Enum "VAT Statement Line Type")
        {
            Caption = 'Type';

            trigger OnValidate()
            begin
                if Type <> xRec.Type then begin
                    TempType := Type;
                    Init();
                    "Statement Template Name" := xRec."Statement Template Name";
                    "Statement Name" := xRec."Statement Name";
                    "Line No." := xRec."Line No.";
                    "Row No." := xRec."Row No.";
                    Description := xRec.Description;
                    Type := TempType;
                end;
            end;
        }
        field(7; "Account Totaling"; Text[30])
        {
            Caption = 'Account Totaling';
            TableRelation = "G/L Account";
            ValidateTableRelation = false;

            trigger OnValidate()
            begin
                if "Account Totaling" <> '' then begin
                    GLAcc.SetFilter("No.", "Account Totaling");
                    GLAcc.SetFilter("Account Type", '<> 0');
                    if GLAcc.FindFirst() then
                        GLAcc.TestField("Account Type", GLAcc."Account Type"::Posting);
                end;
            end;
        }
        field(8; "Gen. Posting Type"; Option)
        {
            Caption = 'Gen. Posting Type';
            OptionCaption = ' ,Purchase,Sale,Settlement,,,,Paid,Advanced,Credit VAT Compens.,Payab. VAT Variation,Deduc. VAT Variation.,Tax Debit Variat.,Tax Deb. Variat. Int.,Tax Credit Variation,Unpaid VAT Prev. Periods,Omit Payable Int.,Special Credit,Prior Period Input VAT,Prior Period Output VAT';
            OptionMembers = " ",Purchase,Sale,Settlement,,,,Paid,Advanced,"Credit VAT Compens.","Payab. VAT Variation","Deduc. VAT Variation.","Tax Debit Variat.","Tax Deb. Variat. Int.","Tax Credit Variation","Unpaid VAT Prev. Periods","Omit Payable Int.","Special Credit","Prior Period Input VAT","Prior Period Output VAT";
        }
        field(9; "VAT Bus. Posting Group"; Code[20])
        {
            Caption = 'VAT Bus. Posting Group';
            TableRelation = "VAT Business Posting Group";
        }
        field(10; "VAT Prod. Posting Group"; Code[20])
        {
            Caption = 'VAT Prod. Posting Group';
            TableRelation = "VAT Product Posting Group";
        }
        field(11; "Row Totaling"; Text[50])
        {
            Caption = 'Row Totaling';
        }
        field(12; "Amount Type"; Enum "VAT Statement Line Amount Type")
        {
            Caption = 'Amount Type';
        }
        field(13; "Calculate with"; Option)
        {
            Caption = 'Calculate with';
            OptionCaption = 'Sign,Opposite Sign';
            OptionMembers = Sign,"Opposite Sign";

            trigger OnValidate()
            begin
                if ("Calculate with" = "Calculate with"::"Opposite Sign") and (Type = Type::"Row Totaling") then
                    FieldError(Type, StrSubstNo(Text000, Type));
            end;
        }
        field(14; Print; Boolean)
        {
            Caption = 'Print';
            InitValue = true;

            trigger OnValidate()
            begin
                if not Print then
                    "Annual VAT Comm. Field" := "Annual VAT Comm. Field"::" ";
            end;
        }
        field(15; "Print with"; Option)
        {
            Caption = 'Print with';
            OptionCaption = 'Sign,Opposite Sign';
            OptionMembers = Sign,"Opposite Sign";
        }
        field(16; "Date Filter"; Date)
        {
            Caption = 'Date Filter';
            Editable = false;
            FieldClass = FlowFilter;
        }
        field(17; "New Page"; Boolean)
        {
            Caption = 'New Page';
        }
        field(18; "Tax Jurisdiction Code"; Code[10])
        {
            Caption = 'Tax Jurisdiction Code';
            TableRelation = "Tax Jurisdiction";
        }
        field(19; "Use Tax"; Boolean)
        {
            Caption = 'Use Tax';
        }
        field(20; "Box No."; Text[30])
        {
            Caption = 'Box No.';
        }
        field(12100; "Round Factor"; Option)
        {
            Caption = 'Round Factor';
            OptionCaption = 'None,1';
            OptionMembers = "None","1";
        }
        field(12124; "Annual VAT Comm. Field"; Option)
        {
            Caption = 'Annual VAT Comm. Field';
            OptionCaption = ' ,CD1 - Total sales,CD1 - Sales with zero VAT,CD1 - VAT exempt sales,CD1 - EU sales,CD2 - Total purchases,CD2 - Purchases with zero VAT,CD2 - VAT exempt purchases,CD2 - EU purchases,CD3 - Gold and Silver Base,CD3 - Gold and Silver Amount,CD3 - Scrap and Recycl. Base,CD3 - Scrap and Recycl. Amount,CD4 - Payable VAT,CD5 - Receivable VAT,,,CD1 - Sales of Capital Goods,CD2 - Purchases of Capital Goods';
            OptionMembers = " ","CD1 - Total sales","CD1 - Sales with zero VAT","CD1 - VAT exempt sales","CD1 - EU sales","CD2 - Total purchases","CD2 - Purchases with zero VAT","CD2 - VAT exempt purchases","CD2 - EU purchases","CD3 - Gold and Silver Base","CD3 - Gold and Silver Amount","CD3 - Scrap and Recycl. Base","CD3 - Scrap and Recycl. Amount","CD4 - Payable VAT","CD5 - Receivable VAT",,,"CD1 - Sales of Capital Goods","CD2 - Purchases of Capital Goods";

            trigger OnValidate()
            begin
                if "Annual VAT Comm. Field" = "Annual VAT Comm. Field"::" " then
                    Print := false
                else
                    Print := true;
            end;
        }
        field(12125; "Activity Code Filter"; Code[6])
        {
            FieldClass = FlowFilter;
            TableRelation = "Activity Code".Code;
        }
        field(12126; "Document Type"; Enum "Gen. Journal Document Type")
        {
            Caption = 'Document Type';
        }
        field(12127; "EU Service"; Boolean)
        {
            Caption = 'EU Service';
        }
#if not CLEANSCHEMA25
        field(12128; "Blacklisted Comm. Field"; Code[10])
        {
            Caption = 'Blacklisted Comm. Field';
            ObsoleteReason = 'Obsolete feature';
            ObsoleteState = Removed;
            ObsoleteTag = '25.0';
        }
#endif
        field(12129; "Refers To Period"; Option)
        {
            Caption = 'Refers To Period';
            OptionCaption = ' ,Current,Current Calendar Year,Previous Calendar Year';
            OptionMembers = " ",Current,"Current Calendar Year","Previous Calendar Year";
        }
#if not CLEANSCHEMA25
        field(12130; "Blacklist Country Transaction"; Boolean)
        {
            Caption = 'Blacklist Country/Region Transaction';
            ObsoleteReason = 'Obsolete feature';
            ObsoleteState = Removed;
            ObsoleteTag = '25.0';
        }
#endif
    }

    keys
    {
        key(Key1; "Statement Template Name", "Statement Name", "Line No.")
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
    }

    var
        GLAcc: Record "G/L Account";
        TempType: Enum "VAT Statement Line Type";

#pragma warning disable AA0074
#pragma warning disable AA0470
        Text000: Label 'must not be %1';
#pragma warning restore AA0470
#pragma warning restore AA0074

    [Scope('OnPrem')]
    procedure Export(var NewVATStatementLine: Record "VAT Statement Line")
    var
        VATStmtLine: Record "VAT Statement Line";
        VATStmtTmpl: Record "VAT Statement Template";
    begin
        VATStmtLine.Copy(NewVATStatementLine);
        VATStmtLine.SetRange("Statement Template Name", VATStmtLine."Statement Template Name");
        VATStmtLine.SetRange("Statement Name", VATStmtLine."Statement Name");
        VATStmtTmpl.Get(VATStmtLine."Statement Template Name");
        VATStmtTmpl.TestField("VAT Stat. Export Report ID");
        REPORT.Run(VATStmtTmpl."VAT Stat. Export Report ID", true, false, VATStmtLine);
    end;

    [Scope('OnPrem')]
    procedure GetAmount(var VATEntry: Record "VAT Entry"): Decimal
    begin
        case "Amount Type" of
            "Amount Type"::Amount:
                exit(VATEntry.GetAmount());
            "Amount Type"::Base:
                exit(VATEntry.GetBase());
            "Amount Type"::"Unrealized Amount":
                exit(VATEntry.GetRemUnrealAmount());
            "Amount Type"::"Unrealized Base":
                exit(VATEntry.GetRemUnrealBase());
            "Amount Type"::"Non-Deductible Amount":
                exit(VATEntry.GetNonDeductAmount());
            "Amount Type"::"Non-Deductible Base":
                exit(VATEntry.GetNonDeductBase());
        end;
    end;
}

