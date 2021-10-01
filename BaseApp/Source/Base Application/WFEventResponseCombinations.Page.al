page 1507 "WF Event/Response Combinations"
{
    ApplicationArea = Suite;
    Caption = 'Workflow Event/Response Combinations';
    PageType = ListPlus;
    UsageCategory = Administration;

    layout
    {
        area(content)
        {
            part(MatrixResponseSubpage; "WF Event/Response Comb. Matrix")
            {
                ApplicationArea = Suite;
                Caption = 'Supported Responses';
            }
        }
    }

    actions
    {
        area(processing)
        {
            action(PreviousSet)
            {
                ApplicationArea = Suite;
                Caption = 'Previous Set';
                Image = PreviousSet;
                Promoted = true;
                PromotedCategory = Process;
                PromotedIsBig = true;
                ToolTip = 'Go to the previous set of data.';

                trigger OnAction()
                begin
                    SetColumns("Matrix Page Step Type"::Previous);
                end;
            }
            action(NextSet)
            {
                ApplicationArea = Suite;
                Caption = 'Next Set';
                Image = NextSet;
                Promoted = true;
                PromotedCategory = Process;
                PromotedIsBig = true;
                ToolTip = 'Go to the next set of data.';

                trigger OnAction()
                begin
                    SetColumns("Matrix Page Step Type"::Next);
                end;
            }
        }
    }

    trigger OnOpenPage()
    begin
        SetColumns("Matrix Page Step Type"::Initial);
    end;

    var
        MatrixManagement: Codeunit "Matrix Management";
        ColumnSetResponses: Text;
        MATRIX_ColumnCaptions_Responses: array[12] of Text[250];
        PKFirstRecInCurrSetResponses: Text;
        ColumnSetLengthResponses: Integer;

    local procedure SetColumns(StepType: Enum "Matrix Page Step Type")
    var
        WorkflowResponse: Record "Workflow Response";
        ResponseRecRef: RecordRef;
    begin
        ResponseRecRef.Open(DATABASE::"Workflow Response");
        MatrixManagement.GenerateMatrixDataExtended(
            ResponseRecRef, StepType.AsInteger(), ArrayLen(MATRIX_ColumnCaptions_Responses),
            WorkflowResponse.FieldNo(Description), PKFirstRecInCurrSetResponses, MATRIX_ColumnCaptions_Responses,
            ColumnSetResponses, ColumnSetLengthResponses, MaxStrLen(MATRIX_ColumnCaptions_Responses[1]));

        CurrPage.MatrixResponseSubpage.PAGE.SetMatrixColumns(MATRIX_ColumnCaptions_Responses, ColumnSetLengthResponses);
        CurrPage.Update(false);
    end;
}

