page 5733 "Item Category Card"
{
    Caption = 'Item Category Card';
    DeleteAllowed = false;
    PageType = Card;
    RefreshOnActivate = true;
    SourceTable = "Item Category";

    layout
    {
        area(content)
        {
            group(General)
            {
                Caption = 'General';
                field("Code"; Code)
                {
                    ApplicationArea = Basic, Suite;
                    NotBlank = true;
                    ToolTip = 'Specifies the item category.';

                    trigger OnValidate()
                    begin
                        if (xRec.Code <> '') and (xRec.Code <> Code) then
                            CurrPage.Attributes.PAGE.SaveAttributes(Code);
                    end;
                }
                field(Description; Rec.Description)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies a description of the item category.';
                }
                field("Parent Category"; Rec."Parent Category")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the item category that this item category belongs to. Item attributes that are assigned to a parent item category also apply to the child item category.';

                    trigger OnValidate()
                    begin
                        if (Code <> '') and ("Parent Category" <> xRec."Parent Category") then
                            PersistCategoryAttributes();
                    end;
                }
            }
            part(Attributes; "Item Category Attributes")
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Attributes';
                ShowFilter = false;
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
                Enabled = CanDelete;
                Image = Delete;
                ToolTip = 'Delete the record.';

                trigger OnAction()
                begin
                    if Confirm(StrSubstNo(DeleteQst, Code)) then
                        Delete(true);
                end;
            }
        }
        area(Promoted)
        {
            group(Category_Process)
            {
                Caption = 'Process';

                actionref(Delete_Promoted; Delete)
                {
                }
            }
        }
    }

    trigger OnAfterGetRecord()
    begin
        if Code <> '' then
            CurrPage.Attributes.PAGE.LoadAttributes(Code);

        CanDelete := not HasChildren();
    end;

    trigger OnInsertRecord(BelowxRec: Boolean): Boolean
    begin
        CurrPage.Attributes.PAGE.SetItemCategoryCode(Code);
    end;

    trigger OnOpenPage()
    begin
        if Code <> '' then
            CurrPage.Attributes.PAGE.LoadAttributes(Code);
    end;

    trigger OnQueryClosePage(CloseAction: Action): Boolean
    begin
        if Code <> '' then
            CurrPage.Attributes.PAGE.SaveAttributes(Code);

        ItemCategoryManagement.CheckPresentationOrder();
    end;

    var
        ItemCategoryManagement: Codeunit "Item Category Management";
        DeleteQst: Label 'Delete %1?', Comment = '%1 - item category name';
        CanDelete: Boolean;

    local procedure PersistCategoryAttributes()
    begin
        CurrPage.Attributes.PAGE.SaveAttributes(Code);
        CurrPage.Attributes.PAGE.LoadAttributes(Code);
        CurrPage.Update(true);
    end;
}

