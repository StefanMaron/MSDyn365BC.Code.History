page 35298 "Pmt Orders Analysis Fact Box"
{
    Caption = 'Pmt Orders Analysis Fact Box';
    DataCaptionExpression = Caption;
    DeleteAllowed = false;
    InsertAllowed = false;
    ModifyAllowed = false;
    PageType = CardPart;
    SaveValues = true;
    SourceTable = "Payment Order";

    layout
    {
        area(content)
        {
            field("Currency Code"; "Currency Code")
            {
                ApplicationArea = Suite;
                Editable = false;
                ToolTip = 'Specifies the currency code associated with this payment order.';
            }
            field(DocCount; DocCount)
            {
                ApplicationArea = Basic, Suite;
                Caption = 'No. of Documents';
                Editable = false;
                ToolTip = 'Specifies the number of documents included.';
            }
            field(Amount; Amount)
            {
                ApplicationArea = Basic, Suite;
                ToolTip = 'Specifies the sum total of the documents included in this payment order.';
            }
            field("Amount (LCY)"; "Amount (LCY)")
            {
                ApplicationArea = Basic, Suite;
                ToolTip = 'Specifies the total amount of all of the documents included in this payment order.';
            }
        }
    }

    actions
    {
    }

    trigger OnAfterGetRecord()
    begin
        UpdateStatistics;
    end;

    var
        Doc: Record "Cartera Doc.";
        DocCount: Integer;

    local procedure UpdateStatistics()
    begin
        Doc.SetRange(Type, Doc.Type::Payable);
        Doc.SetRange("Collection Agent", Doc."Collection Agent"::Bank);
        Doc.SetRange("Bill Gr./Pmt. Order No.", "No.");
        CopyFilter("Global Dimension 1 Filter", Doc."Global Dimension 1 Code");
        CopyFilter("Global Dimension 2 Filter", Doc."Global Dimension 2 Code");
        CopyFilter("Category Filter", Doc."Category Code");
        CopyFilter("Due Date Filter", Doc."Due Date");
        DocCount := Doc.Count();
    end;
}

