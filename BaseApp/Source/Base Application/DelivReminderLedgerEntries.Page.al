page 5005276 "Deliv. Reminder Ledger Entries"
{
    Caption = 'Deliv. Reminder Ledger Entries';
    DataCaptionExpression = CaptionString;
    Editable = false;
    PageType = List;
    SourceTable = "Delivery Reminder Ledger Entry";

    layout
    {
        area(content)
        {
            repeater(Control1140000)
            {
                ShowCaption = false;
                field("Reminder No."; "Reminder No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the number of the delivery reminder.';
                }
                field("Reminder Line No."; "Reminder Line No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the number from the No. field on the delivery reminder line.';
                }
                field("Reminder Level"; "Reminder Level")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the reminder level on the delivery reminder line.';
                }
                field("Days overdue"; "Days overdue")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the day overdue on the delivery reminder line.';
                }
                field("Vendor No."; "Vendor No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the number of the vendor who you want to post a delivery reminder for.';
                }
                field("Order No."; "Order No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the number of the reminded purchase order.';
                }
                field("Order Line No."; "Order Line No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the number of the reminded purchase order line.';
                }
                field(Type; Type)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the entry type.';
                }
                field("No."; "No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies a number that identifies the item, or a number that identifies the G/L account, used when posting the line.';
                }
                field(Quantity; Quantity)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the reminded quantity.';
                }
                field("Reorder Quantity"; "Reorder Quantity")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the reorder quantity.';
                }
                field("Remaining Quantity"; "Remaining Quantity")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the remaining quantity.';
                }
                field("Posting Date"; "Posting Date")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the posting date of the delivery reminder.';
                }
                field("Document Date"; "Document Date")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the document date of the delivery reminder.';
                }
                field("User ID"; "User ID")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the ID of the user who posted the delivery reminder.';
                }
                field("Entry No."; "Entry No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies a consecutive number for each new entry.';
                }
            }
        }
    }

    actions
    {
        area(processing)
        {
            action("&Navigate")
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Find entries...';
                Image = Navigate;
                Promoted = true;
                PromotedCategory = Process;
                ToolTip = 'Find all entries and documents that exist for the document number and posting date on the selected entry or document.';

                trigger OnAction()
                begin
                    Navigate.SetDoc("Posting Date", "Reminder No.");
                    Navigate.Run();
                end;
            }
        }
    }

    trigger OnFindRecord(Which: Text): Boolean
    begin
        CaptionString := '';

        CurrentFilter := GetFilter("Order No.");
        if CurrentFilter <> '' then
            CaptionString :=
              Text1140000 + CurrentFilter;

        CurrentFilter := GetFilter("Vendor No.");
        if CurrentFilter <> '' then begin
            if CaptionString <> '' then
                CaptionString := CaptionString + Text1140001;
            CaptionString :=
              CaptionString + ' ' + CurrentFilter;
        end;

        exit(Find(Which));
    end;

    var
        Text1140000: Label 'PurchOrder ';
        Text1140001: Label ' Customer';
        Navigate: Page Navigate;
        CaptionString: Text[100];
        CurrentFilter: Text[30];
}

