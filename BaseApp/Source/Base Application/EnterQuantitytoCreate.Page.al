page 6513 "Enter Quantity to Create"
{
    Caption = 'Enter Quantity to Create';
    PageType = StandardDialog;
    SaveValues = true;

    layout
    {
        area(content)
        {
            group(General)
            {
                Caption = 'General';
                field(ItemNo; ItemNo)
                {
                    ApplicationArea = ItemTracking;
                    Caption = 'Item No.';
                    Editable = false;

                    trigger OnLookup(var Text: Text): Boolean
                    begin
                        Item."No." := ItemNo;
                        PAGE.RunModal(0, Item);
                    end;
                }
                field(VariantCode; VariantCode)
                {
                    ApplicationArea = Planning;
                    Caption = 'Variant Code';
                    Editable = false;

                    trigger OnLookup(var Text: Text): Boolean
                    begin
                        ItemVariant.Reset();
                        ItemVariant.SetRange("Item No.", ItemNo);
                        ItemVariant."Item No." := ItemNo;
                        ItemVariant.Code := VariantCode;
                        PAGE.RunModal(0, ItemVariant);
                    end;
                }
                field(QtyToCreate; QtyToCreate)
                {
                    ApplicationArea = ItemTracking;
                    Caption = 'Quantity to Create';
                }
                field(CreateNewLotNo; CreateNewLotNo)
                {
                    ApplicationArea = ItemTracking;
                    Caption = 'Create New Lot No.';
                }
            }
        }
    }

    actions
    {
    }

    trigger OnOpenPage()
    begin
        ItemNo := InitItemNo;
        VariantCode := InitVariantCode;
        QtyToCreate := InitQtyToCreate;
        CreateNewLotNo := InitCreateNewLotNo;
    end;

    var
        Item: Record Item;
        ItemVariant: Record "Item Variant";
        ItemNo: Code[20];
        VariantCode: Code[10];
        QtyToCreate: Integer;
        CreateNewLotNo: Boolean;
        InitItemNo: Code[20];
        InitVariantCode: Code[10];
        InitQtyToCreate: Integer;
        InitCreateNewLotNo: Boolean;

    procedure SetFields(SetItemNo: Code[20]; SetVariantCode: Code[10]; SetQtyToCreate: Integer; SetCreateNewLotNo: Boolean)
    begin
        InitItemNo := SetItemNo;
        InitVariantCode := SetVariantCode;
        InitQtyToCreate := SetQtyToCreate;
        InitCreateNewLotNo := SetCreateNewLotNo;
    end;

    procedure GetFields(var GetQtyToCreate: Integer; var GetCreateNewLotNo: Boolean)
    begin
        GetQtyToCreate := QtyToCreate;
        GetCreateNewLotNo := CreateNewLotNo;
    end;
}

