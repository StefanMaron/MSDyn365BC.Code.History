page 567 "Dimension Selection-Change"
{
    Caption = 'Dimension Selection';
    DeleteAllowed = false;
    InsertAllowed = false;
    PageType = List;
    SourceTable = "Dimension Selection Buffer";
    SourceTableTemporary = true;

    layout
    {
        area(content)
        {
            repeater(Control1)
            {
                ShowCaption = false;
                field(Selected; Selected)
                {
                    ApplicationArea = Dimensions;
                    ToolTip = 'Specifies that this dimension will be included.';
                }
                field("Code"; Code)
                {
                    ApplicationArea = Dimensions;
                    Editable = false;
                    ToolTip = 'Specifies the code for the dimension.';
                }
                field(Description; Description)
                {
                    ApplicationArea = Dimensions;
                    Editable = false;
                    ToolTip = 'Specifies a description of the dimension.';
                }
                field("Dimension Value Filter"; "Dimension Value Filter")
                {
                    ApplicationArea = Dimensions;
                    ToolTip = 'Specifies the dimension value that the analysis view is based on.';
                }
                field("New Dimension Value Code"; "New Dimension Value Code")
                {
                    ApplicationArea = Dimensions;
                    ToolTip = 'Specifies the new dimension value to that you are changing to.';
                }
            }
        }
    }

    actions
    {
    }

    procedure GetDimSelBuf(var TheDimSelectionBuf: Record "Dimension Selection Buffer")
    begin
        TheDimSelectionBuf.DeleteAll();
        if Find('-') then
            repeat
                TheDimSelectionBuf := Rec;
                TheDimSelectionBuf.Insert();
            until Next = 0;
    end;

    procedure InsertDimSelBuf(NewSelected: Boolean; NewCode: Text[30]; NewDescription: Text[30]; NewNewDimValueCode: Code[20]; NewDimValueFilter: Text[250])
    var
        Dim: Record Dimension;
        GLAcc: Record "G/L Account";
        BusinessUnit: Record "Business Unit";
    begin
        if NewDescription = '' then begin
            if Dim.Get(NewCode) then
                NewDescription := Dim.Name;
        end;

        Init;
        Selected := NewSelected;
        Code := NewCode;
        Description := NewDescription;
        if NewSelected then begin
            "New Dimension Value Code" := NewNewDimValueCode;
            "Dimension Value Filter" := NewDimValueFilter;
        end;
        case Code of
            GLAcc.TableCaption:
                "Filter Lookup Table No." := DATABASE::"G/L Account";
            BusinessUnit.TableCaption:
                "Filter Lookup Table No." := DATABASE::"Business Unit";
        end;
        Insert;
    end;
}

