report 99001021 "Refresh Planning Demand"
{
    Caption = 'Refresh Planning Demand';
    ProcessingOnly = true;

    dataset
    {
        dataitem("Requisition Line"; "Requisition Line")
        {
            DataItemTableView = SORTING("Worksheet Template Name", "Journal Batch Name", "Line No.") WHERE("Planning Level" = CONST(0));
            RequestFilterFields = "Worksheet Template Name", "Journal Batch Name", "Line No.";

            trigger OnAfterGetRecord()
            begin
                Window.Update(1, "No.");
                Window.Update(2, "Starting Date");

                PlngLnMgt.Calculate("Requisition Line", Direction, CalcRoutings, CalcComponents, 0);
                OnRequisitionLineOnAfterGetRecordOnBeforeModify("Requisition Line");
                Modify();
            end;

            trigger OnPreDataItem()
            begin
                SetRange(Type, Type::Item);
                SetRange("Action Message", "Action Message"::" ", "Action Message"::New);
                SetRange("Planning Level", 0);

                Window.Open(
                  Text000 +
                  Text001 +
                  Text002);
            end;
        }
    }

    requestpage
    {
        SaveValues = true;

        layout
        {
            area(content)
            {
                group(Options)
                {
                    Caption = 'Options';
                    field(Direction; Direction)
                    {
                        ApplicationArea = Manufacturing;
                        Caption = 'Scheduling Direction';
                        OptionCaption = 'Forward,Backward';
                        ToolTip = 'Specifies the scheduling method - forward or backward.';
                    }
                    group(Calculate)
                    {
                        Caption = 'Calculate';
                        field(CalcRoutings; CalcRoutings)
                        {
                            ApplicationArea = Manufacturing;
                            Caption = 'Routings';
                            ToolTip = 'Specifies if you want the program to refresh the routing.';
                        }
                        field(CalcComponents; CalcComponents)
                        {
                            ApplicationArea = Planning;
                            Caption = 'Component Need';
                            ToolTip = 'Specifies if you want the program to recalculate the BOM.';
                        }
                    }
                }
            }
        }

        actions
        {
        }

        trigger OnInit()
        begin
            Direction := Direction::Backward;
        end;
    }

    labels
    {
    }

    trigger OnInitReport()
    begin
        CalcRoutings := true;
        CalcComponents := true;
    end;

    var
        Text000: Label 'Refreshing planning lines...\\';
        Text001: Label 'Item No.       #1##########\';
        Text002: Label 'Starting Date  #2##########';
        PlngLnMgt: Codeunit "Planning Line Management";
        Window: Dialog;
        Direction: Option Forward,Backward;
        CalcRoutings: Boolean;
        CalcComponents: Boolean;

    procedure InitializeRequest(SchDirection: Option; CalcRouting: Boolean; CalcCompNeed: Boolean)
    begin
        Direction := SchDirection;
        CalcRoutings := CalcRouting;
        CalcComponents := CalcCompNeed;
    end;

    [IntegrationEvent(false, false)]
    local procedure OnRequisitionLineOnAfterGetRecordOnBeforeModify(var RequisitionLine: Record "Requisition Line")
    begin
    end;
}

