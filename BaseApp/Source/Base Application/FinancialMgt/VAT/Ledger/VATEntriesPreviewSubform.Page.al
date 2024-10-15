namespace Microsoft.Finance.VAT.Ledger;

using Microsoft.Finance.GeneralLedger.Preview;
using Microsoft.Finance.VAT.Setup;

page 1572 "VAT Entries Preview Subform"
{
    PageType = ListPart;
    SourceTable = "VAT Entry Posting Preview";
    SourceTableTemporary = true;
    Editable = false;
    Caption = 'VAT Entries';

    layout
    {
        area(Content)
        {
            repeater(GroupName)
            {
                ShowAsTree = true;
                IndentationColumn = Rec.Indentation;
                ShowCaption = false;
                TreeInitialState = CollapseAll;
                field("Gen. Bus. Posting Group"; Rec."Gen. Bus. Posting Group")
                {
                    ApplicationArea = Suite;
                    ToolTip = 'Specifies the vendor''s or customer''s trade type to link transactions made for this business partner with the appropriate general ledger account according to the general posting setup.';
                    Visible = false;
                }
                field("Gen. Prod. Posting Group"; Rec."Gen. Prod. Posting Group")
                {
                    ApplicationArea = Suite;
                    ToolTip = 'Specifies the item''s product type to link transactions made for this item with the appropriate general ledger account according to the general posting setup.';
                    Visible = false;
                }
                field("VAT Bus. Posting Group"; Rec."VAT Bus. Posting Group")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the VAT specification of the involved customer or vendor to link transactions made for this record with the appropriate general ledger account according to the VAT posting setup.';
                    StyleExpr = Emphasize;
                    Style = Strong;
                }
                field("VAT Prod. Posting Group"; Rec."VAT Prod. Posting Group")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the VAT specification of the involved item or resource to link transactions made for this record with the appropriate general ledger account according to the VAT posting setup.';
                    StyleExpr = Emphasize;
                    Style = Strong;
                }
                field("Posting Date"; Rec."Posting Date")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the VAT entry''s posting date.';
                }
                field("Document Date"; Rec."Document Date")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the date when the related document was created.';
                    Visible = false;
                }
                field("Document No."; Rec."Document No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the document number on the VAT entry.';
                }
                field("Document Type"; Rec."Document Type")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the document type that the VAT entry belongs to.';
                }
                field(Type; Rec.Type)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the type of the VAT entry.';
                }
                field(Base; Rec.Base)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the amount that the VAT amount (the amount shown in the Amount field) is calculated from.';
                    StyleExpr = Emphasize;
                    Style = Strong;
                }
                field(Amount; Rec.Amount)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the amount of the VAT entry in LCY.';
                    StyleExpr = Emphasize;
                    Style = Strong;
                }
                field("VAT Difference"; Rec."VAT Difference")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the difference between the calculated VAT amount and a VAT amount that you have entered manually.';
                    Visible = false;
                }
                field("Additional-Currency Base"; Rec."Additional-Currency Base")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the amount that the VAT amount is calculated from if you post in an additional reporting currency.';
                    Visible = false;
                }
                field("Additional-Currency Amount"; Rec."Additional-Currency Amount")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the amount of the VAT entry. The amount is in the additional reporting currency.';
                    Visible = false;
                }
                field("Add.-Curr. VAT Difference"; Rec."Add.-Curr. VAT Difference")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies, in the additional reporting currency, the VAT difference that arises when you make a correction to a VAT amount on a sales or purchase document.';
                    Visible = false;
                }
                field("VAT Calculation Type"; Rec."VAT Calculation Type")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies how VAT will be calculated for purchases or sales of items with this particular combination of VAT business posting group and VAT product posting group.';
                }
                field("Bill-to/Pay-to No."; Rec."Bill-to/Pay-to No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the number of the bill-to customer or pay-to vendor that the entry is linked to.';
                }
                field("VAT Registration No."; Rec."VAT Registration No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the VAT registration number of the customer or vendor that the entry is linked to.';
                    Visible = false;
                }
                field("Ship-to/Order Address Code"; Rec."Ship-to/Order Address Code")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the address code of the ship-to customer or order-from vendor that the entry is linked to.';
                    Visible = false;
                }
                field("Country/Region Code"; Rec."Country/Region Code")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the country/region of the address.';
                }
                field("EU 3-Party Trade"; Rec."EU 3-Party Trade")
                {
                    ApplicationArea = Suite;
                    ToolTip = 'Specifies if the transaction is related to trade with a third party within the EU.';
                }
                field(Closed; Rec.Closed)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies whether the VAT entry has been closed by the Calc. and Post VAT Settlement batch job.';
                }
                field("Closed by Entry No."; Rec."Closed by Entry No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the number of the VAT entry that has closed the entry, if the VAT entry was closed with the Calc. and Post VAT Settlement batch job.';
                }
                field("Internal Ref. No."; Rec."Internal Ref. No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the internal reference number for the line.';
                }
                field(Reversed; Rec.Reversed)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies if the entry has been part of a reverse transaction.';
                    Visible = false;
                }
                field("Reversed by Entry No."; Rec."Reversed by Entry No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the number of the correcting entry. If the field Specifies a number, the entry cannot be reversed again.';
                    Visible = false;
                }
                field("Reversed Entry No."; Rec."Reversed Entry No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the number of the original entry that was undone by the reverse transaction.';
                    Visible = false;
                }
                field("EU Service"; Rec."EU Service")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies if this VAT entry is to be reported as a service in the periodic VAT reports.';
                    Visible = false;
                }
            }
        }
    }
    trigger OnAfterGetRecord()
    begin
        Emphasize := Rec.Indentation = 0;
    end;

    protected var
        Emphasize: Boolean;

    procedure Set(PostingPreviewEventHandler: Codeunit "Posting Preview Event Handler")
    var
        TempVATEntryPostingPreview: Record "VAT Entry Posting Preview" temporary;
        RecRef: RecordRef;
    begin
        Rec.Reset();
        Rec.DeleteAll();
        TempVATEntryPostingPreview.Reset();
        TempVATEntryPostingPreview.DeleteAll();

        PostingPreviewEventHandler.GetEntries(Database::"VAT Entry", RecRef);

        LoadBufferAsHierarchicalView(RecRef, TempVATEntryPostingPreview);

        Rec.Copy(TempVATEntryPostingPreview, true);
    end;

    local procedure LoadBufferAsHierarchicalView(var RecRef: RecordRef; var TempVATEntryPostingPreview: Record "VAT Entry Posting Preview" temporary)
    var
        TempVATPostingSetup: Record "VAT Posting Setup" temporary;
        TempVATEntry: Record "VAT Entry" temporary;
        EntryNo: Integer;
    begin
        if RecRef.FindSet() then
            repeat
                RecRef.SetTable(TempVATEntry);
                TempVATEntry.Insert();

                if not TempVATPostingSetup.Get(TempVATEntry."VAT Bus. Posting Group", TempVATEntry."VAT Prod. Posting Group") then begin
                    TempVATPostingSetup."VAT Bus. Posting Group" := TempVATEntry."VAT Bus. Posting Group";
                    TempVATPostingSetup."VAT Prod. Posting Group" := TempVATEntry."VAT Prod. Posting Group";
                    TempVATPostingSetup.Insert();
                end;
            until RecRef.Next() = 0;

        EntryNo := 1;
        if TempVATPostingSetup.FindSet() then
            repeat
                TempVATEntry.SetRange("VAT Bus. Posting Group", TempVATPostingSetup."VAT Bus. Posting Group");
                TempVATEntry.SetRange("VAT Prod. Posting Group", TempVATPostingSetup."VAT Prod. Posting Group");
                TempVATEntry.CalcSums(Base, Amount);
                TempVATEntryPostingPreview.Init();
                TempVATEntryPostingPreview."Entry No." := EntryNo;
                TempVATEntryPostingPreview."VAT Bus. Posting Group" := TempVATPostingSetup."VAT Bus. Posting Group";
                TempVATEntryPostingPreview."VAT Prod. Posting Group" := TempVATPostingSetup."VAT Prod. Posting Group";
                TempVATEntryPostingPreview.Base := TempVATEntry.Base;
                TempVATEntryPostingPreview.Amount := TempVATEntry.Amount;
                TempVATEntryPostingPreview.Indentation := 0;
                OnLoadBufferAsHierarchicalViewOnBeforeInsertGroupEntry(TempVATEntryPostingPreview, TempVATEntry);
                TempVATEntryPostingPreview.Insert();
                EntryNo += 1;

                if TempVATEntry.FindSet() then
                    repeat
                        TempVATEntryPostingPreview.Init();
                        TempVATEntryPostingPreview.TransferFields(TempVATEntry);
                        TempVATEntryPostingPreview."VAT Entry No." := TempVATEntry."Entry No.";
                        TempVATEntryPostingPreview."Entry No." := EntryNo;
                        TempVATEntryPostingPreview.Indentation := 1;
                        OnLoadBufferAsHierarchicalViewOnBeforeInsertEntry(TempVATEntryPostingPreview, TempVATEntry);
                        TempVATEntryPostingPreview.Insert();
                        EntryNo += 1;
                    until TempVATEntry.Next() = 0;
            until TempVATPostingSetup.Next() = 0;
    end;

    [IntegrationEvent(false, false)]
    local procedure OnLoadBufferAsHierarchicalViewOnBeforeInsertGroupEntry(var TempVATEntryPostingPreview: Record "VAT Entry Posting Preview" temporary; var TempVATEntry: Record "VAT Entry" temporary)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnLoadBufferAsHierarchicalViewOnBeforeInsertEntry(var TempVATEntryPostingPreview: Record "VAT Entry Posting Preview" temporary; var TempVATEntry: Record "VAT Entry" temporary)
    begin
    end;
}