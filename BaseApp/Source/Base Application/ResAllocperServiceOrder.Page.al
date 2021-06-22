page 6008 "Res. Alloc. per Service Order"
{
    Caption = 'Resource Allocated per Service Order';
    DataCaptionExpression = '';
    DeleteAllowed = false;
    InsertAllowed = false;
    LinksAllowed = false;
    PageType = Card;
    SaveValues = true;
    SourceTable = "Service Header";

    layout
    {
        area(content)
        {
            group(General)
            {
                Caption = 'General';
                field(ResourceFilter; ResourceFilter)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Resource Filter';
                    Lookup = true;
                    LookupPageID = "Resource List";
                    TableRelation = Resource;
                    ToolTip = 'Specifies the resource that the allocations apply to.';
                }
            }
            group("Matrix Options")
            {
                Caption = 'Matrix Options';
                field(PeriodType; PeriodType)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'View by';
                    OptionCaption = 'Day,Week,Month,Quarter,Year,Accounting Period';
                    ToolTip = 'Specifies by which period amounts are displayed.';

                    trigger OnValidate()
                    begin
                        DateControl;
                        SetColumns(SetWanted::Initial);
                        PeriodTypeOnAfterValidate;
                    end;
                }
                field(DateFilter; DateFilter)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Date Filter';
                    ToolTip = 'Specifies the dates that will be used to filter the amounts in the window.';

                    trigger OnValidate()
                    begin
                        DateControl;
                        SetColumns(SetWanted::Initial);
                        DateFilterOnAfterValidate;
                    end;
                }
                field(ColumnsSet; ColumnsSet)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Column set';
                    Editable = false;
                    ToolTip = 'Specifies the range of values that are displayed in the matrix window, for example, the total period. To change the contents of the field, choose Next Set or Previous Set.';
                }
            }
        }
    }

    actions
    {
        area(processing)
        {
            action(ShowMatrix)
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Show Matrix';
                Image = ShowMatrix;
                Promoted = true;
                PromotedCategory = Process;
                PromotedOnly = true;
                ToolTip = 'Open the matrix window to see data according to the specified values.';

                trigger OnAction()
                var
                    HorizontalRecord: Record "Service Order Allocation";
                    ResPerServiceOrderMatrix: Page "Res. All. per Service  Matrix";
                begin
                    HorizontalRecord.SetRange("Resource No.", ResourceFilter);
                    ServiceHeader.SetFilter("Resource Filter", ResourceFilter);
                    ResPerServiceOrderMatrix.Load(ServiceHeader, HorizontalRecord, MatrixColumnCaptions, MatrixRecords, CurrSetLength);
                    ResPerServiceOrderMatrix.RunModal;
                end;
            }
            action("Previous Set")
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Previous Set';
                Image = PreviousSet;
                Promoted = true;
                PromotedCategory = Process;
                PromotedIsBig = true;
                PromotedOnly = true;
                ToolTip = 'Go to the previous set of data.';

                trigger OnAction()
                begin
                    SetColumns(SetWanted::Previous);
                end;
            }
            action("Next Set")
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Next Set';
                Image = NextSet;
                Promoted = true;
                PromotedCategory = Process;
                PromotedOnly = true;
                ToolTip = 'Go to the next set of data.';

                trigger OnAction()
                begin
                    SetColumns(SetWanted::Next);
                end;
            }
        }
    }

    trigger OnOpenPage()
    begin
        SetColumns(SetWanted::Initial);
        if HasFilter then
            ResourceFilter := GetFilter("Resource Filter");
    end;

    var
        MatrixRecords: array[32] of Record Date;
        ResRec2: Record Resource;
        ServiceHeader: Record "Service Header";
        FilterTokens: Codeunit "Filter Tokens";
        DateFilter: Text;
        ResourceFilter: Text;
        PeriodType: Option Day,Week,Month,Quarter,Year,"Accounting Period";
        SetWanted: Option Initial,Previous,Same,Next;
        PKFirstRecInCurrSet: Text[1024];
        MatrixColumnCaptions: array[32] of Text[100];
        ColumnsSet: Text[1024];
        CurrSetLength: Integer;

    local procedure DateControl()
    begin
        FilterTokens.MakeDateFilter(DateFilter);
        ResRec2.SetFilter("Date Filter", DateFilter);
        DateFilter := ResRec2.GetFilter("Date Filter");
    end;

    procedure SetColumns(SetWanted: Option Initial,Previous,Same,Next)
    var
        MatrixMgt: Codeunit "Matrix Management";
    begin
        MatrixMgt.GeneratePeriodMatrixData(SetWanted, 32, false, PeriodType, DateFilter,
          PKFirstRecInCurrSet, MatrixColumnCaptions, ColumnsSet, CurrSetLength, MatrixRecords);
    end;

    local procedure PeriodTypeOnAfterValidate()
    begin
        CurrPage.Update;
    end;

    local procedure DateFilterOnAfterValidate()
    begin
        CurrPage.Update;
    end;
}

