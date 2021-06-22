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
                field(CreateSNInfo; CreateSNInfo)
                {
                    ApplicationArea = ItemTracking;
                    Caption = 'Create SN Information';
                    ToolTip = 'Create Serial Number Information card for each serial number.';
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
        CreateSNInfo := InitCreateSNInfo;
    end;

    var
        Item: Record Item;
        ItemVariant: Record "Item Variant";
        ItemNo: Code[20];
        VariantCode: Code[10];
        QtyToCreate: Integer;
        CreateNewLotNo: Boolean;
        CreateSNInfo: Boolean;
        InitItemNo: Code[20];
        InitVariantCode: Code[10];
        InitQtyToCreate: Integer;
        InitCreateNewLotNo: Boolean;
        InitCreateSNInfo: Boolean;

    [Obsolete('Replaced by SetFields procedure with additional parameter.', '18.0')]
    procedure SetFields(SetItemNo: Code[20]; SetVariantCode: Code[10]; SetQtyToCreate: Integer; SetCreateNewLotNo: Boolean)
    begin
        InitItemNo := SetItemNo;
        InitVariantCode := SetVariantCode;
        InitQtyToCreate := SetQtyToCreate;
        InitCreateNewLotNo := SetCreateNewLotNo;
    end;

    [Obsolete('Replaced by GetFields procedure with additional parameter.', '18.0')]
    procedure GetFields(var GetQtyToCreate: Integer; var GetCreateNewLotNo: Boolean)
    begin
        GetQtyToCreate := QtyToCreate;
        GetCreateNewLotNo := CreateNewLotNo;
    end;

    procedure SetFields(SetItemNo: Code[20]; SetVariantCode: Code[10]; SetQtyToCreate: Integer; SetCreateNewLotNo: Boolean; SetCreateSNInfo: Boolean)
    begin
        InitItemNo := SetItemNo;
        InitVariantCode := SetVariantCode;
        InitQtyToCreate := SetQtyToCreate;
        InitCreateNewLotNo := SetCreateNewLotNo;
        InitCreateSNInfo := SetCreateSNInfo;
    end;

    procedure GetFields(var GetQtyToCreate: Integer; var GetCreateNewLotNo: Boolean; var GetCreateSNInfo: Boolean)
    begin
        GetQtyToCreate := QtyToCreate;
        GetCreateNewLotNo := CreateNewLotNo;
        GetCreateSNInfo := CreateSNInfo;
    end;
}

