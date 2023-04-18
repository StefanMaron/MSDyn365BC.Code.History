page 568 "Dimension Selection"
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
                field("Code"; Code)
                {
                    ApplicationArea = Dimensions;
                    Editable = false;
                    ToolTip = 'Specifies the code for the dimension.';
                }
                field(Description; Rec.Description)
                {
                    ApplicationArea = Dimensions;
                    Editable = false;
                    ToolTip = 'Specifies a description of the dimension.';
                }
            }
        }
    }

    actions
    {
    }

    procedure GetDimSelCode(): Text[30]
    begin
        exit(Code);
    end;

    procedure InsertDimSelBuf(NewSelected: Boolean; NewCode: Text[30]; NewDescription: Text[30])
    var
        Dim: Record Dimension;
        GLAcc: Record "G/L Account";
        BusinessUnit: Record "Business Unit";
    begin
        if NewDescription = '' then
            if Dim.Get(NewCode) then
                NewDescription := Dim.GetMLName(GlobalLanguage);

        Init();
        Selected := NewSelected;
        Code := NewCode;
        Description := NewDescription;
        case Code of
            GLAcc.TableCaption:
                "Filter Lookup Table No." := DATABASE::"G/L Account";
            BusinessUnit.TableCaption:
                "Filter Lookup Table No." := DATABASE::"Business Unit";
        end;
        OnInsertDimSelBufOnBeforeInsert(Rec);
        Insert();
    end;

    [IntegrationEvent(false, false)]
    local procedure OnInsertDimSelBufOnBeforeInsert(var DimensionSelectionBuffer: Record "Dimension Selection Buffer")
    begin
    end;
}

