table 251 "Gen. Product Posting Group"
{
    Caption = 'Gen. Product Posting Group';
    DataCaptionFields = "Code", Description;
    LookupPageID = "Gen. Product Posting Groups";

    fields
    {
        field(1; "Code"; Code[20])
        {
            Caption = 'Code';
            NotBlank = true;
        }
        field(2; Description; Text[100])
        {
            Caption = 'Description';
        }
        field(3; "Def. VAT Prod. Posting Group"; Code[20])
        {
            Caption = 'Def. VAT Prod. Posting Group';
            TableRelation = "VAT Product Posting Group";

            trigger OnValidate()
            var
                ConfirmManagement: Codeunit "Confirm Management";
            begin
                if CurrFieldNo = 0 then
                    exit;

                if "Def. VAT Prod. Posting Group" <> xRec."Def. VAT Prod. Posting Group" then begin
                    GLAcc.SetCurrentKey("Gen. Prod. Posting Group");
                    GLAcc.SetRange("Gen. Prod. Posting Group", Code);
                    GLAcc.SetRange("VAT Prod. Posting Group", xRec."Def. VAT Prod. Posting Group");
                    if GLAcc.Find('-') then
                        if ConfirmManagement.GetResponseOrDefault(
                             StrSubstNo(
                               Text000, GLAcc.FieldCaption("VAT Prod. Posting Group"),
                               GLAcc.TableCaption, GLAcc.FieldCaption("Gen. Prod. Posting Group"),
                               Code, xRec."Def. VAT Prod. Posting Group"), true)
                        then
                            repeat
                                GLAcc2 := GLAcc;
                                GLAcc2."VAT Prod. Posting Group" := "Def. VAT Prod. Posting Group";
                                GLAcc2.Modify();
                            until GLAcc.Next = 0;

                    Item.SetCurrentKey("Gen. Prod. Posting Group");
                    Item.SetRange("Gen. Prod. Posting Group", Code);
                    Item.SetRange("VAT Prod. Posting Group", xRec."Def. VAT Prod. Posting Group");
                    if Item.Find('-') then
                        if ConfirmManagement.GetResponseOrDefault(
                             StrSubstNo(
                               Text000, Item.FieldCaption("VAT Prod. Posting Group"),
                               Item.TableCaption, Item.FieldCaption("Gen. Prod. Posting Group"),
                               Code, xRec."Def. VAT Prod. Posting Group"), true)
                        then
                            repeat
                                Item2 := Item;
                                Item2."VAT Prod. Posting Group" := "Def. VAT Prod. Posting Group";
                                Item2.Modify();
                            until Item.Next = 0;

                    Res.SetCurrentKey("Gen. Prod. Posting Group");
                    Res.SetRange("Gen. Prod. Posting Group", Code);
                    Res.SetRange("VAT Prod. Posting Group", xRec."Def. VAT Prod. Posting Group");
                    if Res.Find('-') then
                        if ConfirmManagement.GetResponseOrDefault(
                             StrSubstNo(
                               Text000, Res.FieldCaption("VAT Prod. Posting Group"),
                               Res.TableCaption, Res.FieldCaption("Gen. Prod. Posting Group"),
                               Code, xRec."Def. VAT Prod. Posting Group"), true)
                        then
                            repeat
                                Res2 := Res;
                                Res2."VAT Prod. Posting Group" := "Def. VAT Prod. Posting Group";
                                Res2.Modify();
                            until Res.Next = 0;

                    ItemCharge.SetCurrentKey("Gen. Prod. Posting Group");
                    ItemCharge.SetRange("Gen. Prod. Posting Group", Code);
                    ItemCharge.SetRange("VAT Prod. Posting Group", xRec."Def. VAT Prod. Posting Group");
                    if ItemCharge.Find('-') then
                        if ConfirmManagement.GetResponseOrDefault(
                             StrSubstNo(
                               Text000, ItemCharge.FieldCaption("VAT Prod. Posting Group"),
                               ItemCharge.TableCaption, ItemCharge.FieldCaption("Gen. Prod. Posting Group"),
                               Code, xRec."Def. VAT Prod. Posting Group"), true)
                        then
                            repeat
                                ItemCharge2 := ItemCharge;
                                ItemCharge2."VAT Prod. Posting Group" := "Def. VAT Prod. Posting Group";
                                ItemCharge2.Modify();
                            until ItemCharge.Next = 0;
                end;
            end;
        }
        field(4; "Auto Insert Default"; Boolean)
        {
            Caption = 'Auto Insert Default';
            InitValue = true;
        }
    }

    keys
    {
        key(Key1; "Code")
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
        fieldgroup(Brick; "Code", Description, "Def. VAT Prod. Posting Group")
        {
        }
    }

    var
        Text000: Label 'Change all occurrences of %1 in %2\where %3 is %4\and %1 is %5.';
        GLAcc: Record "G/L Account";
        GLAcc2: Record "G/L Account";
        Item: Record Item;
        Item2: Record Item;
        Res: Record Resource;
        Res2: Record Resource;
        ItemCharge: Record "Item Charge";
        ItemCharge2: Record "Item Charge";

    procedure ValidateVatProdPostingGroup(var GenProdPostingGrp: Record "Gen. Product Posting Group"; EnteredGenProdPostingGroup: Code[20]): Boolean
    begin
        if EnteredGenProdPostingGroup <> '' then
            GenProdPostingGrp.Get(EnteredGenProdPostingGroup)
        else
            GenProdPostingGrp.Init();
        exit(GenProdPostingGrp."Auto Insert Default");
    end;
}

