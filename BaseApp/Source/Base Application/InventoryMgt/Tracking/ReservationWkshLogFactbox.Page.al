namespace Microsoft.Inventory.Tracking;

using Microsoft.Assembly.Document;
using Microsoft.Inventory.Transfer;
using Microsoft.Manufacturing.Document;
using Microsoft.Projects.Project.Planning;
using Microsoft.Sales.Document;
using Microsoft.Service.Document;

page 331 "Reservation Wksh. Log Factbox"
{
    PageType = ListPart;
    Editable = false;
    ApplicationArea = Reservation;
    SourceTable = "Reservation Worksheet Log";
    Caption = 'Latest changes';

    layout
    {
        area(Content)
        {
            repeater(Log)
            {
                ShowCaption = false;

                field("Record ID"; Format(Rec."Record ID"))
                {
                    Caption = 'Demand Line';
                    ToolTip = 'Specifies the demand line that was changed.';
                }
                field(Quantity; Rec.Quantity)
                {
                    Caption = 'Reserved Quantity';
                    ToolTip = 'Specifies how many units were reserved for the demand line.';
                }
            }
        }
    }

    actions
    {
        area(Processing)
        {
            action("Empty Log")
            {
                Caption = 'Empty Log';
                Image = ClearLog;
                ToolTip = 'Deletes all entries in the log.';

                trigger OnAction()
                var
                    ReservationWorksheetLog: Record "Reservation Worksheet Log";
                begin
                    ReservationWorksheetLog.SetRange("Journal Batch Name", Rec."Journal Batch Name");
                    ReservationWorksheetLog.DeleteAll();
                end;
            }
            action("Show Document")
            {
                Caption = 'Show Document';
                Image = ViewDocumentLine;
                Scope = Repeater;
                ToolTip = 'Shows the document that was changed.';

                trigger OnAction()
                var
                    SalesLine: Record "Sales Line";
                    TransferLine: Record "Transfer Line";
                    ServiceLine: Record "Service Line";
                    JobPlanningLine: Record "Job Planning Line";
                    AssemblyLine: Record "Assembly Line";
                    ProdOrderComponent: Record "Prod. Order Component";
                begin
                    if SalesLine.Get(Rec."Record ID") then begin
                        SalesLine.SetRecFilter();
                        Page.Run(0, SalesLine);
                        exit;
                    end;
                    if TransferLine.Get(Rec."Record ID") then begin
                        TransferLine.SetRecFilter();
                        Page.Run(0, TransferLine);
                        exit;
                    end;
                    if ServiceLine.Get(Rec."Record ID") then begin
                        ServiceLine.SetRecFilter();
                        Page.Run(0, ServiceLine);
                        exit;
                    end;
                    if JobPlanningLine.Get(Rec."Record ID") then begin
                        JobPlanningLine.SetRecFilter();
                        Page.Run(0, JobPlanningLine);
                        exit;
                    end;
                    if AssemblyLine.Get(Rec."Record ID") then begin
                        AssemblyLine.SetRecFilter();
                        Page.Run(0, AssemblyLine);
                        exit;
                    end;
                    if ProdOrderComponent.Get(Rec."Record ID") then begin
                        ProdOrderComponent.SetRecFilter();
                        Page.Run(0, ProdOrderComponent);
                        exit;
                    end;
                end;
            }
        }
    }
}