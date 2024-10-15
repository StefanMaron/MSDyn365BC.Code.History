﻿pageextension 18246 "GST General Journal Ext" extends "General Journal"
{
    layout
    {
        addafter("Account No.")
        {
            field("GST on Advance Payment"; Rec."GST on Advance Payment")
            {
                ApplicationArea = Basic, Suite;
                ToolTip = 'Specifies if GST is required to be calculated on Advance Payment.';
                trigger OnValidate()
                begin
                    CallTaxEngine();
                end;
            }
            field("GST TCS"; Rec."GST TCS")
            {
                ApplicationArea = Basic, Suite;
                ToolTip = 'Specifies if GST TCS is calculated on the journal line.';
            }
            field("GST TCS State Code"; Rec."GST TCS State Code")
            {
                ApplicationArea = Basic, Suite;
                ToolTip = 'Specifies the state code for which GST TCS is applicable on the journal line.';
            }
            field("GST TDS/TCS Base Amount"; Rec."GST TDS/TCS Base Amount")
            {
                ApplicationArea = Basic, Suite;
                ToolTip = 'Specifies the GST TDS/TCS Base amount for the journal line.';
            }
            field("GST TDS"; Rec."GST TDS")
            {
                ApplicationArea = Basic, Suite;
                ToolTip = 'Specifies if GST TDS is calculated on the journal line.';
            }
            field("GST Group Code"; Rec."GST Group Code")
            {
                ApplicationArea = Basic, Suite;
                ToolTip = 'Specifies the GST Group code for the calculation of GST on journal line.';
                trigger OnValidate()
                begin
                    CallTaxEngine();
                end;
            }
            field("HSN/SAC Code"; Rec."HSN/SAC Code")
            {
                ApplicationArea = Basic, Suite;
                ToolTip = 'Specifies the HSN/SAC code for the calculation of GST on journal line.';
                trigger OnValidate()
                begin
                    CallTaxEngine();
                end;
            }
            field("Location State Code"; Rec."Location State Code")
            {
                ApplicationArea = Basic, Suite;
                ToolTip = 'Specifies the sate code mentioned in location used in the transaction.';
            }
            field("GST Group Type"; Rec."GST Group Type")
            {
                ApplicationArea = Basic, Suite;
                ToolTip = 'Specifies whether the GST Group is of goods or service category for the journal line.';
            }
            field("Vendor GST Reg. No."; Rec."Vendor GST Reg. No.")
            {
                ApplicationArea = Basic, Suite;
                ToolTip = 'Specifies the GST registration number of the Vendor specified on the journal line.';
            }
            field("Location GST Reg. No."; Rec."Location GST Reg. No.")
            {
                ApplicationArea = Basic, Suite;
                ToolTip = 'Specifies the GST registration number of the Location specified on the journal line.';
            }
            field("GST Vendor Type"; Rec."GST Vendor Type")
            {
                ApplicationArea = Basic, Suite;
                ToolTip = 'Specifies the GST Vendor type for the vendor specified in account number field on journal line.';
            }
            field("Without Bill Of Entry"; Rec."Without Bill Of Entry")
            {
                ApplicationArea = Basic, Suite;
                ToolTip = 'Specifies whether the journal line is without the Bill of Entry.';
                trigger OnValidate()
                begin
                    CallTaxEngine();
                end;
            }
            field("Bill of Entry No."; Rec."Bill of Entry No.")
            {
                ApplicationArea = Basic, Suite;
                ToolTip = 'Specifies the bill of entry number. It is a document number which is submitted to custom department';
            }
            field("Bill of Entry Date"; Rec."Bill of Entry Date")
            {
                ApplicationArea = Basic, Suite;
                ToolTip = 'Specifies the Bill of Entry Date for the journal line.';
            }
            field("GST Assessable Value"; Rec."GST Assessable Value")
            {
                ApplicationArea = Basic, Suite;
                ToolTip = 'Specifies the GST Assessable Value for the journal line.';
                trigger OnValidate()
                begin
                    CallTaxEngine();
                end;
            }
            field("Custom Duty Amount"; Rec."Custom Duty Amount")
            {
                ApplicationArea = Basic, Suite;
                ToolTip = 'Specifies the Custom Duty amount for the journal line';
                trigger OnValidate()
                begin
                    CallTaxEngine();
                end;
            }
            field("Amount Excl. GST"; Rec."Amount Excl. GST")
            {
                ApplicationArea = Basic, Suite;
                ToolTip = 'Specifies the amount excluding GST for the journal line.';
            }
        }
        modify(Amount)
        {
            trigger OnAfterValidate()
            begin
                CallTaxEngine();
            end;
        }
        modify("Account No.")
        {
            trigger OnAfterValidate()
            begin
                CallTaxEngine();
            end;
        }
        modify("Bal. Account No.")
        {
            trigger OnAfterValidate()
            begin
                CallTaxEngine();
            end;
        }
        modify("Document Type")
        {
            trigger OnAfterValidate()
            begin
                CallTaxEngine();
            end;
        }
        modify("Posting Date")
        {
            trigger OnAfterValidate()
            begin
                CallTaxEngine();
            end;
        }

    }
    actions
    {
        addafter("&Line")
        {
            action("Bank Charges")
            {
                ApplicationArea = All;
                Caption = 'Bank Charges';
                Image = BankContact;
                Promoted = true;
                PromotedCategory = Process;
                ToolTip = 'View or change Bank Charges of Bank Payment Voucher';
                RunObject = Page "Journal Bank Charges";
                RunPageView = SORTING("Journal Template Name", "Journal Batch Name", "Line No.", "Bank Charge");
                RunPageLink = "Journal Template Name" = FIELD("Journal Template Name"), "Journal Batch Name" = FIELD("Journal Batch Name"), "Line No." = FIELD("Line No.");
            }
        }
        addafter(IncomingDocument)
        {
            action("Update Reference Invoice No.")
            {
                Promoted = true;
                PromotedCategory = Process;
                ApplicationArea = Basic, Suite;
                Image = ApplyEntries;
                ToolTip = 'Specifies the function through which reference number can be updated in the document.';

                trigger OnAction()
                var
                    i: Integer;
                begin
                    i := 0;
                    //blank OnAction created as we have a subscriber of this action in "Reference Invoice No. Mgt." codeunit;
                end;
            }
        }
    }
    local procedure CallTaxEngine()
    var
        CalculateTax: Codeunit "Calculate Tax";
    begin
        CurrPage.SaveRecord();
        CalculateTax.CallTaxEngineOnGenJnlLine(Rec, xRec);
    end;
}