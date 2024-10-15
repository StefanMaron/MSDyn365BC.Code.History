namespace Microsoft.Warehouse.Activity.History;

using Microsoft.Warehouse.Activity;
using Microsoft.Warehouse.Comment;
using Microsoft.Warehouse.Journal;

page 9343 "Registered Whse. Put-aways"
{
    ApplicationArea = Warehouse;
    Caption = 'Registered Warehouse Put-away List';
    CardPageID = "Registered Put-away";
    Editable = false;
    PageType = List;
    SourceTable = "Registered Whse. Activity Hdr.";
    SourceTableView = where(Type = const("Put-away"));
    UsageCategory = History;

    layout
    {
        area(content)
        {
            repeater(Control1)
            {
                ShowCaption = false;
                field(Type; Rec.Type)
                {
                    ApplicationArea = Warehouse;
                    ToolTip = 'Specifies the type of activity that the warehouse performed on the lines attached to the header, such as put-away, pick or movement.';
                    Visible = false;
                }
                field("No."; Rec."No.")
                {
                    ApplicationArea = Warehouse;
                    ToolTip = 'Specifies the number of the involved entry or record, according to the specified number series.';
                }
                field("Whse. Activity No."; Rec."Whse. Activity No.")
                {
                    ApplicationArea = Warehouse;
                    ToolTip = 'Specifies the warehouse activity number from which the activity was registered.';
                }
                field("Location Code"; Rec."Location Code")
                {
                    ApplicationArea = Warehouse;
                    ToolTip = 'Specifies the code of the location in which the registered warehouse activity occurred.';
                }
                field("Assigned User ID"; Rec."Assigned User ID")
                {
                    ApplicationArea = Warehouse;
                    ToolTip = 'Specifies the ID of the user who is responsible for the document.';
                }
                field("Sorting Method"; Rec."Sorting Method")
                {
                    ApplicationArea = Warehouse;
                    ToolTip = 'Specifies the method by which the lines were sorted on the warehouse header, such as by item, or bin code.';
                }
                field("No. Series"; Rec."No. Series")
                {
                    ApplicationArea = Warehouse;
                    ToolTip = 'Specifies the number series from which entry or record numbers are assigned to new entries or records.';
                }
                field("Assignment Date"; Rec."Assignment Date")
                {
                    ApplicationArea = Warehouse;
                    ToolTip = 'Specifies the date when the user was assigned the activity.';
                    Visible = false;
                }
            }
        }
        area(factboxes)
        {
            systempart(Control1900383207; Links)
            {
                ApplicationArea = RecordLinks;
                Visible = false;
            }
            systempart(Control1905767507; Notes)
            {
                ApplicationArea = Notes;
                Visible = true;
            }
        }
    }

    actions
    {
        area(navigation)
        {
            group("&Put-away")
            {
                Caption = '&Put-away';
                Image = CreatePutAway;
                action("Co&mments")
                {
                    ApplicationArea = Warehouse;
                    Caption = 'Co&mments';
                    Image = ViewComments;
                    RunObject = Page "Warehouse Comment Sheet";
                    RunPageLink = "Table Name" = const("Rgstrd. Whse. Activity Header"),
                                  Type = field(Type),
                                  "No." = field("No.");
                    ToolTip = 'View or add comments for the record.';
                }
            }
        }
        area(processing)
        {
            action("Delete Registered Movements")
            {
                ApplicationArea = All;
                Caption = 'Delete Registered Put-aways';
                Image = Delete;
                ToolTip = 'Delete registered warehouse put-aways.';

                trigger OnAction()
                var
                    DeleteRegisteredWhseDocs: Report "Delete Registered Whse. Docs.";
                    XmlParameters: Text;
                begin
                    XmlParameters := DeleteRegisteredWhseDocs.RunRequestPage(ReportParametersTxt);
                    if XmlParameters <> '' then
                        REPORT.Execute(REPORT::"Delete Registered Whse. Docs.", XmlParameters);
                end;
            }
        }
        area(Promoted)
        {
            group(Category_Process)
            {
                Caption = 'Process';

                actionref("Delete Registered Movements_Promoted"; "Delete Registered Movements")
                {
                }
            }
        }
    }

    trigger OnOpenPage()
    var
        WMSManagement: Codeunit "WMS Management";
    begin
        Rec.FilterGroup(2);
        Rec.SetFilter("Location Code", WMSManagement.GetWarehouseEmployeeLocationFilter(CopyStr(UserId, 1, 50)));
        Rec.FilterGroup(0);
    end;

    var
        ReportParametersTxt: Label '<?xml version="1.0" standalone="yes"?><ReportParameters name="Delete Registered Whse. Docs." id="5755"><DataItems><DataItem name="Registered Whse. Activity Hdr.">VERSION(1) SORTING(Field1,Field2) where(Field1=1(1))</DataItem></DataItems></ReportParameters>', Locked = true;
}

