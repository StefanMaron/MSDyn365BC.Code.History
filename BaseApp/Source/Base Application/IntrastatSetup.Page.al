page 328 "Intrastat Setup"
{
    ApplicationArea = BasicEU;
    Caption = 'Intrastat Setup';
    DeleteAllowed = false;
    InsertAllowed = false;
    SourceTable = "Intrastat Setup";
    UsageCategory = Administration;

    layout
    {
        area(content)
        {
            group(General)
            {
                Caption = 'General';
                field("Report Receipts"; "Report Receipts")
                {
                    ApplicationArea = BasicEU;
                    ToolTip = 'Specifies that you must include arrivals of received goods in Intrastat reports.';
                }
                field("Report Shipments"; "Report Shipments")
                {
                    ApplicationArea = BasicEU;
                    ToolTip = 'Specifies that you must include shipments of dispatched items in Intrastat reports.';
                }
                field("Intrastat Contact Type"; "Intrastat Contact Type")
                {
                    ApplicationArea = BasicEU;
                    OptionCaption = ' ,Contact,Vendor';
                    ToolTip = 'Specifies the Intrastat contact type.';
                }
                field("Intrastat Contact No."; "Intrastat Contact No.")
                {
                    ApplicationArea = BasicEU;
                    ToolTip = 'Specifies the Intrastat contact.';
                }
            }
            group("Default Transactions")
            {
                Caption = 'Default Transactions';
                field("Default Transaction Type"; "Default Trans. - Purchase")
                {
                    ApplicationArea = BasicEU;
                    ToolTip = 'Specifies the default transaction type for regular sales shipments, service shipments, and purchase receipts.';
                }
                field("Default Trans. Type - Returns"; "Default Trans. - Return")
                {
                    ApplicationArea = BasicEU;
                    ToolTip = 'Specifies the default transaction type for sales returns, service returns, and purchase returns';
                }
            }
        }
    }

    actions
    {
        area(processing)
        {
            action(IntrastatChecklistSetup)
            {
                ApplicationArea = BasicEU;
                Caption = 'Intrastat Checklist Setup';
                Image = Column;
                Promoted = true;
                PromotedCategory = Process;
                PromotedIsBig = true;
                PromotedOnly = true;
                RunObject = Page "Intrastat Checklist Setup";
                ToolTip = 'View and edit fields to be verified by the Intrastat journal check.';
            }
        }
    }

    trigger OnOpenPage()
    begin
        Init;
        if not Get then
            Insert(true);
    end;
}

