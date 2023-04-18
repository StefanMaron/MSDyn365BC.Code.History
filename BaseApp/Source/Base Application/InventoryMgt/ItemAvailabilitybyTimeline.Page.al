#pragma warning disable AS0031
#pragma warning disable AS0032
#pragma warning disable AS0018
#pragma warning disable AS0106 // Protected variables ItemNo, LocationFilter, VariantFilter, ForecastName, and IncludeBlanketOrders were removed before AS0106 was introduced.
page 5540 "Item Availability by Timeline"
#pragma warning restore AS0106
{
    Caption = 'Item Availability by Timeline';
    DeleteAllowed = false;
    InsertAllowed = false;
    LinksAllowed = false;
    PageType = Worksheet;
    SourceTable = "Timeline Event Change";
    SourceTableTemporary = true;
    SourceTableView = SORTING("Due Date")
                          ORDER(Ascending);
    ObsoleteState = Pending;
    ObsoleteReason = 'TimelineVisualizer control has been deprecated and has never worked on the web client.';
    ObsoleteTag = '21.0';
#if not CLEAN21
    layout
    {
        area(content)
        {
            group(Options)
            {
                Caption = 'Options';
                field("<ItemNo>"; ItemNo)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Item No.';
                    Importance = Promoted;
                    TableRelation = Item;
                    ToolTip = 'Specifies the number of the item you want to view item availability for.';
                }
                field("<VariantFilter>"; VariantFilter)
                {
                    ApplicationArea = Planning;
                    Caption = 'Variant Filter';
                    Importance = Promoted;
                    ToolTip = 'Specifies a variant code to view only the projected available balance for that variant of the item.';
                }
                field("<LocationFilter>"; LocationFilter)
                {
                    ApplicationArea = Location;
                    Caption = 'Location Filter';
                    Importance = Promoted;
                    ToolTip = 'Specifies a location code to view only the projected available balance for the item at that location.';
                }
                field("<LastUpdateTime>"; LastUpdateTime)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Last Updated';
                    Editable = false;
                    Importance = Promoted;
                    ToolTip = 'Specifies when the availability figures in the Item Availability by Timeline window were last updated.';
                }
                field("<ForecastName>"; ForecastName)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Forecast Name';
                    Importance = Promoted;
                    TableRelation = "Production Forecast Name";
                    ToolTip = 'Specifies a demand forecast you want to include as anticipated demand in the graphical view of projected available balance.';

                    trigger OnValidate()
                    var
                        ForecastName2: Code[10];
                    begin
                        ForecastName2 := ForecastName;
                        OnForecaseNameOnValidateOnBeforeInitAndCreateTimelineEvents(IncludeBlanketOrders, ForecastName);
                        ForecastName := ForecastName2;
                    end;
                }
                field("<IncludeBlanketOrders>"; IncludeBlanketOrders)
                {
                    ApplicationArea = Suite;
                    Caption = 'Include Blanket Sales Orders';
                    Importance = Promoted;
                    ToolTip = 'Specifies if you want to include anticipated demand from blanket sales orders in the graphical view of projected available balance.';
                }
            }
            group(Timeline)
            {
                Caption = 'Timeline';
                field(Visualization; DeprecatedFuncTxt)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Deprecated';
                    ToolTip = 'Deprecated';
                }
            }
            grid(changeListGroup)
            {
                Caption = 'Event Changes';
                repeater(changeList)
                {
                    Caption = 'Change List';
                    field(ActionMessage; ActionMsg)
                    {
                        ApplicationArea = Manufacturing;
                        Caption = 'Action Message';
                        Editable = false;
                        ToolTip = 'Specifies the action to take to rebalance the demand-supply situation shown in the graph on the Timeline FastTab.';
                    }
                    field(Description; Description)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Description';
                        Editable = false;
                        ToolTip = 'Specifies the description of the planning worksheet lines that are represented on the Timeline FastTab.';
                    }
                    field("Original Due Date"; Rec."Original Due Date")
                    {
                        ApplicationArea = Basic, Suite;
                        ToolTip = 'Specifies the due date that is stated on the existing supply order, when an action message proposes to reschedule the order.';
                    }
                    field("Due Date"; Rec."Due Date")
                    {
                        ApplicationArea = Basic, Suite;
                        ToolTip = 'Specifies the due date of the suggested supply order that the line on the Event Changes FastTab represents.';

                    }
                    field("Original Quantity"; Rec."Original Quantity")
                    {
                        ApplicationArea = Basic, Suite;
                        ToolTip = 'Specifies the quantity on the supply order, when an action message suggests a change to the quantity on the order.';
                    }
                    field(Quantity; Rec.Quantity)
                    {
                        ApplicationArea = Basic, Suite;
                        ToolTip = 'Specifies the quantity of the suggested supply order that the line on the Event Changes FastTab represents.';
                    }
                    field("Reference No."; Rec."Reference No.")
                    {
                        ApplicationArea = Basic, Suite;
                        ToolTip = 'Specifies the reference number for the item in the timeline event change table.';
                        Visible = false;
                    }
                }
            }
        }
    }

    actions
    {
        area(processing)
        {
            action(Delete)
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Delete';
                Image = Delete;
                ShortCutKey = 'Ctrl+Delete';
                ToolTip = 'Delete the record.';

                trigger OnAction()
                begin
                    Message(DeprecatedFuncTxt);
                end;
            }
            action("<Reload>")
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Reload';
                Image = Refresh;
                ToolTip = 'Update the window with values created by other users since you opened the window.';

                trigger OnAction()
                begin
                    Message(DeprecatedFuncTxt);
                end;
            }
            action("<TransferChanges>")
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Save Changes';
                Image = SuggestLines;
                ToolTip = 'Transfer the changes to the planning worksheet lines.';

                trigger OnAction()
                begin
                    Message(DeprecatedFuncTxt);
                end;
            }
        }
        area(Promoted)
        {
            group(Category_Process)
            {
                Caption = 'Process';

                actionref("<Reload>_Promoted"; "<Reload>")
                {
                }
                actionref("<TransferChanges>_Promoted"; "<TransferChanges>")
                {
                }
                actionref(Delete_Promoted; Delete)
                {
                }
            }
        }
    }

    var
        Description: Text[250];
        ActionMsg: Enum "Action Message Type";
        LastUpdateTime: DateTime;
        DeprecatedFuncTxt: Label 'This function has been deprecated.';

    protected var
        ItemNo: Code[20];
        LocationFilter: Text;
        VariantFilter: Text;
        [InDataSet]
        ForecastName: Code[10];
        [InDataSet]
        IncludeBlanketOrders: Boolean;

    [Scope('OnPrem')]
    procedure InitAndCreateTimelineEvents()
    begin
    end;

    procedure SetItem(var NewItem: Record Item)
    begin
    end;

    procedure SetForecastName(NewForcastName: Code[10])
    begin
    end;

    procedure SetWorksheet(NewTemplateName: Code[10]; NewWorksheetName: Code[10])
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnForecaseNameOnValidateOnBeforeInitAndCreateTimelineEvents(var IncludeBlanketOrders: Boolean; ForecastName: Code[10])
    begin
    end;
#endif
#pragma warning restore AS0031
#pragma warning restore AS0032
#pragma warning restore AS0018
}
