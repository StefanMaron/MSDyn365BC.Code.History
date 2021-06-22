page 9237 "Resource Capacity Matrix"
{
    Caption = 'Resource Capacity Matrix';
    Editable = true;
    LinksAllowed = false;
    PageType = ListPart;
    SourceTable = Resource;

    layout
    {
        area(content)
        {
            repeater(Control1)
            {
                ShowCaption = false;
                field("No."; "No.")
                {
                    ApplicationArea = Jobs;
                    ToolTip = 'Specifies the number of the involved entry or record, according to the specified number series.';
                }
                field(Name; Name)
                {
                    ApplicationArea = Jobs;
                    ToolTip = 'Specifies a description of the resource.';
                }
                field(Field1; MATRIX_CellData[1])
                {
                    ApplicationArea = Jobs;
                    CaptionClass = '3,' + MATRIX_ColumnCaption[1];

                    trigger OnDrillDown()
                    begin
                        MatrixOnDrillDown(1)
                    end;

                    trigger OnValidate()
                    begin
                        ValidateCapacity(1);
                    end;
                }
                field(Field2; MATRIX_CellData[2])
                {
                    ApplicationArea = Jobs;
                    CaptionClass = '3,' + MATRIX_ColumnCaption[2];

                    trigger OnDrillDown()
                    begin
                        MatrixOnDrillDown(2)
                    end;

                    trigger OnValidate()
                    begin
                        ValidateCapacity(2);
                    end;
                }
                field(Field3; MATRIX_CellData[3])
                {
                    ApplicationArea = Jobs;
                    CaptionClass = '3,' + MATRIX_ColumnCaption[3];

                    trigger OnDrillDown()
                    begin
                        MatrixOnDrillDown(3)
                    end;

                    trigger OnValidate()
                    begin
                        ValidateCapacity(3);
                    end;
                }
                field(Field4; MATRIX_CellData[4])
                {
                    ApplicationArea = Jobs;
                    CaptionClass = '3,' + MATRIX_ColumnCaption[4];

                    trigger OnDrillDown()
                    begin
                        MatrixOnDrillDown(4)
                    end;

                    trigger OnValidate()
                    begin
                        ValidateCapacity(4);
                    end;
                }
                field(Field5; MATRIX_CellData[5])
                {
                    ApplicationArea = Jobs;
                    CaptionClass = '3,' + MATRIX_ColumnCaption[5];

                    trigger OnDrillDown()
                    begin
                        MatrixOnDrillDown(5)
                    end;

                    trigger OnValidate()
                    begin
                        ValidateCapacity(5);
                    end;
                }
                field(Field6; MATRIX_CellData[6])
                {
                    ApplicationArea = Jobs;
                    CaptionClass = '3,' + MATRIX_ColumnCaption[6];

                    trigger OnDrillDown()
                    begin
                        MatrixOnDrillDown(6)
                    end;

                    trigger OnValidate()
                    begin
                        ValidateCapacity(6);
                    end;
                }
                field(Field7; MATRIX_CellData[7])
                {
                    ApplicationArea = Jobs;
                    CaptionClass = '3,' + MATRIX_ColumnCaption[7];

                    trigger OnDrillDown()
                    begin
                        MatrixOnDrillDown(7)
                    end;

                    trigger OnValidate()
                    begin
                        ValidateCapacity(7);
                    end;
                }
                field(Field8; MATRIX_CellData[8])
                {
                    ApplicationArea = Jobs;
                    CaptionClass = '3,' + MATRIX_ColumnCaption[8];

                    trigger OnDrillDown()
                    begin
                        MatrixOnDrillDown(8)
                    end;

                    trigger OnValidate()
                    begin
                        ValidateCapacity(8);
                    end;
                }
                field(Field9; MATRIX_CellData[9])
                {
                    ApplicationArea = Jobs;
                    CaptionClass = '3,' + MATRIX_ColumnCaption[9];

                    trigger OnDrillDown()
                    begin
                        MatrixOnDrillDown(9)
                    end;

                    trigger OnValidate()
                    begin
                        ValidateCapacity(9);
                    end;
                }
                field(Field10; MATRIX_CellData[10])
                {
                    ApplicationArea = Jobs;
                    CaptionClass = '3,' + MATRIX_ColumnCaption[10];

                    trigger OnDrillDown()
                    begin
                        MatrixOnDrillDown(10)
                    end;

                    trigger OnValidate()
                    begin
                        ValidateCapacity(10);
                    end;
                }
                field(Field11; MATRIX_CellData[11])
                {
                    ApplicationArea = Jobs;
                    CaptionClass = '3,' + MATRIX_ColumnCaption[11];

                    trigger OnDrillDown()
                    begin
                        MatrixOnDrillDown(11)
                    end;

                    trigger OnValidate()
                    begin
                        ValidateCapacity(11);
                    end;
                }
                field(Field12; MATRIX_CellData[12])
                {
                    ApplicationArea = Jobs;
                    CaptionClass = '3,' + MATRIX_ColumnCaption[12];

                    trigger OnDrillDown()
                    begin
                        MatrixOnDrillDown(12)
                    end;

                    trigger OnValidate()
                    begin
                        ValidateCapacity(12);
                    end;
                }
            }
        }
    }

    actions
    {
        area(processing)
        {
            group("&Resource")
            {
                Caption = '&Resource';
                Image = Resource;
                action(Card)
                {
                    ApplicationArea = Jobs;
                    Caption = 'Card';
                    Image = EditLines;
                    RunObject = Page "Resource Card";
                    RunPageLink = "No." = FIELD("No."),
                                  "Date Filter" = FIELD("Date Filter"),
                                  "Unit of Measure Filter" = FIELD("Unit of Measure Filter"),
                                  "Chargeable Filter" = FIELD("Chargeable Filter");
                    ShortCutKey = 'Shift+F7';
                    ToolTip = 'View or change detailed information about the record on the document or journal line.';
                }
                action(Statistics)
                {
                    ApplicationArea = Jobs;
                    Caption = 'Statistics';
                    Image = Statistics;
                    Promoted = true;
                    PromotedCategory = Process;
                    RunObject = Page "Resource Statistics";
                    RunPageLink = "No." = FIELD("No."),
                                  "Date Filter" = FIELD("Date Filter"),
                                  "Unit of Measure Filter" = FIELD("Unit of Measure Filter"),
                                  "Chargeable Filter" = FIELD("Chargeable Filter");
                    ShortCutKey = 'F7';
                    ToolTip = 'View statistical information, such as the value of posted entries, for the record.';
                }
                action("Co&mments")
                {
                    ApplicationArea = Comments;
                    Caption = 'Co&mments';
                    Image = ViewComments;
                    RunObject = Page "Comment Sheet";
                    RunPageLink = "Table Name" = CONST(Resource),
                                  "No." = FIELD("No.");
                    ToolTip = 'View or add comments for the record.';
                }
                action(Dimensions)
                {
                    ApplicationArea = Dimensions;
                    Caption = 'Dimensions';
                    Image = Dimensions;
                    RunObject = Page "Default Dimensions";
                    RunPageLink = "Table ID" = CONST(156),
                                  "No." = FIELD("No.");
                    ShortCutKey = 'Alt+D';
                    ToolTip = 'View or edit dimensions, such as area, project, or department, that you can assign to sales and purchase documents to distribute costs and analyze transaction history.';
                }
                action("Ledger E&ntries")
                {
                    ApplicationArea = Jobs;
                    Caption = 'Ledger E&ntries';
                    Image = CustomerLedger;
                    RunObject = Page "Resource Ledger Entries";
                    RunPageLink = "Resource No." = FIELD("No.");
                    RunPageView = SORTING("Resource No.");
                    ShortCutKey = 'Ctrl+F7';
                    ToolTip = 'View the history of transactions that have been posted for the selected record.';
                }
            }
            group("&Prices")
            {
                Caption = '&Prices';
                Image = Price;
                action(Costs)
                {
                    ApplicationArea = Jobs;
                    Caption = 'Costs';
                    Image = ResourceCosts;
                    RunObject = Page "Resource Costs";
                    RunPageLink = Type = CONST(Resource),
                                  Code = FIELD("No.");
                    ToolTip = 'View or change detailed information about costs for the resource.';
                }
                action(Prices)
                {
                    ApplicationArea = Jobs;
                    Caption = 'Prices';
                    Image = Price;
                    RunObject = Page "Resource Prices";
                    RunPageLink = Type = CONST(Resource),
                                  Code = FIELD("No.");
                    ToolTip = 'View or edit prices for the resource.';
                }
            }
            group("Plan&ning")
            {
                Caption = 'Plan&ning';
                Image = Planning;
                action("&Set Capacity")
                {
                    ApplicationArea = Jobs;
                    Caption = '&Set Capacity';
                    RunObject = Page "Resource Capacity Settings";
                    RunPageLink = "No." = FIELD("No.");
                    ToolTip = 'Change the capacity of the resource, such as a technician.';
                }
                action("Resource A&vailability")
                {
                    ApplicationArea = Jobs;
                    Caption = 'Resource A&vailability';
                    Image = Calendar;
                    RunObject = Page "Resource Availability";
                    RunPageLink = "No." = FIELD("No."),
                                  "Unit of Measure Filter" = FIELD("Unit of Measure Filter"),
                                  "Chargeable Filter" = FIELD("Chargeable Filter");
                    ToolTip = 'View a summary of resource capacities, the quantity of resource hours allocated to jobs on order, the quantity allocated to service orders, the capacity assigned to jobs on quote, and the resource availability.';
                }
            }
        }
    }

    trigger OnAfterGetRecord()
    var
        MATRIX_CurrentColumnOrdinal: Integer;
    begin
        MATRIX_CurrentColumnOrdinal := 0;
        while MATRIX_CurrentColumnOrdinal < MATRIX_NoOfMatrixColumns do begin
            MATRIX_CurrentColumnOrdinal := MATRIX_CurrentColumnOrdinal + 1;
            MATRIX_OnAfterGetRecord(MATRIX_CurrentColumnOrdinal);
        end;
    end;

    var
        MatrixRecords: array[32] of Record Date;
        QtyType: Option "Net Change","Balance at Date";
        MATRIX_NoOfMatrixColumns: Integer;
        MATRIX_CellData: array[32] of Decimal;
        MATRIX_ColumnCaption: array[32] of Text[1024];

    local procedure SetDateFilter(ColumnID: Integer)
    begin
        if QtyType = QtyType::"Net Change" then
            if MatrixRecords[ColumnID]."Period Start" = MatrixRecords[ColumnID]."Period End" then
                SetRange("Date Filter", MatrixRecords[ColumnID]."Period Start")
            else
                SetRange("Date Filter", MatrixRecords[ColumnID]."Period Start", MatrixRecords[ColumnID]."Period End")
        else
            SetRange("Date Filter", 0D, MatrixRecords[ColumnID]."Period End");
    end;

    local procedure MATRIX_OnAfterGetRecord(ColumnID: Integer)
    begin
        SetDateFilter(ColumnID);
        CalcFields(Capacity);
        if Capacity <> 0 then
            MATRIX_CellData[ColumnID] := Capacity
        else
            MATRIX_CellData[ColumnID] := 0;
    end;

    procedure Load(QtyType1: Option "Net Change","Balance at Date"; MatrixColumns1: array[32] of Text[1024]; var MatrixRecords1: array[32] of Record Date; NoOfMatrixColumns1: Integer)
    var
        i: Integer;
    begin
        QtyType := QtyType1;
        CopyArray(MATRIX_ColumnCaption, MatrixColumns1, 1);
        for i := 1 to ArrayLen(MatrixRecords) do
            MatrixRecords[i].Copy(MatrixRecords1[i]);
        MATRIX_NoOfMatrixColumns := NoOfMatrixColumns1;
    end;

    local procedure MatrixOnDrillDown(ColumnID: Integer)
    var
        ResCapacityEntries: Record "Res. Capacity Entry";
        IsHandled: Boolean;
    begin
        SetDateFilter(ColumnID);
        ResCapacityEntries.SetCurrentKey("Resource No.", Date);
        ResCapacityEntries.SetRange("Resource No.", "No.");
        ResCapacityEntries.SetFilter(Date, GetFilter("Date Filter"));
        IsHandled := false;
        OnAfterMatrixOnDrillDown(ResCapacityEntries, IsHandled);
        if IsHandled then
            exit;

        PAGE.Run(0, ResCapacityEntries);
    end;

    local procedure ValidateCapacity(MATRIX_ColumnOrdinal: Integer)
    begin
        SetDateFilter(MATRIX_ColumnOrdinal);
        CalcFields(Capacity);
        Validate(Capacity, MATRIX_CellData[MATRIX_ColumnOrdinal]);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterMatrixOnDrillDown(var ResCapacityEntry: Record "Res. Capacity Entry"; var IsHandled: Boolean)
    begin
    end;
}

