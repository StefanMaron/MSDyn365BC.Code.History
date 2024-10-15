#if not CLEAN21
page 2190 "O365 Invoicing Sales Doc. List"
{
    Caption = 'Invoices';
    DeleteAllowed = false;
    Editable = false;
    LinksAllowed = false;
    PageType = List;
    RefreshOnActivate = true;
    SourceTable = "O365 Sales Document";
    SourceTableTemporary = true;
    SourceTableView = sorting("Sell-to Customer Name");
    ObsoleteReason = 'Microsoft Invoicing has been discontinued.';
    ObsoleteState = Pending;
    ObsoleteTag = '21.0';

    layout
    {
        area(content)
        {
            repeater(Control2)
            {
                ShowCaption = false;
                field("No."; Rec."No.")
                {
                    ApplicationArea = Invoicing, Basic, Suite;
                    ToolTip = 'Specifies the number of the involved entry or record, according to the specified number series.';
                }
                field("Sell-to Customer Name"; Rec."Sell-to Customer Name")
                {
                    ApplicationArea = Invoicing, Basic, Suite;
                    ToolTip = 'Specifies the name of the customer.';
                }
                field("Document Date"; Rec."Document Date")
                {
                    ApplicationArea = Invoicing, Basic, Suite;
                    ToolTip = 'Specifies the date when the related document was created.';
                }
                field("Total Invoiced Amount"; Rec."Total Invoiced Amount")
                {
                    ApplicationArea = Invoicing, Basic, Suite;
                    Style = Ambiguous;
                    StyleExpr = NOT Rec.Posted;
                    ToolTip = 'Specifies the total invoiced amount.';
                }
                field("Outstanding Status"; Rec."Outstanding Status")
                {
                    ApplicationArea = Invoicing, Basic, Suite;
                    StyleExpr = OutStandingStatusStyle;
                    ToolTip = 'Specifies the outstanding amount, meaning the amount not paid.';
                }
            }
        }
    }

    actions
    {
        area(processing)
        {
            action(Open)
            {
                ApplicationArea = Invoicing, Basic, Suite;
                Caption = 'Open';
                Image = DocumentEdit;
                Scope = Repeater;
                ShortCutKey = 'Return';
                ToolTip = 'Open the card for the selected record.';
                Visible = false;

                trigger OnAction()
                begin
                    Rec.OpenDocument();
                end;
            }
        }
        area(Promoted)
        {
            group(Category_Report)
            {
                Caption = 'Report', Comment = 'Generated from the PromotedActionCategories property index 2.';
            }
            group(Category_Category4)
            {
                Caption = 'Invoice', Comment = 'Generated from the PromotedActionCategories property index 3.';
            }
        }
    }

    trigger OnAfterGetRecord()
    begin
        OutStandingStatusStyle := '';
        if Rec.IsOverduePostedInvoice() then
            OutStandingStatusStyle := 'Unfavorable'
        else
            if Rec.Posted and not Rec.Canceled and (Rec."Outstanding Amount" <= 0) then
                OutStandingStatusStyle := 'Favorable';
    end;

    trigger OnFindRecord(Which: Text): Boolean
    begin
        exit(Rec.OnFind(Which));
    end;

    trigger OnInit()
    begin
        Rec.SetSortByDocDate();
    end;

    trigger OnNextRecord(Steps: Integer): Integer
    begin
        exit(Rec.OnNext(Steps));
    end;

    var
        OutStandingStatusStyle: Text[30];
}
#endif

