Table 18012 "Retrun & Reco. Components"
{
    Fields
    {
        Field(1; "Component ID"; Integer)
        {
            Caption = 'Component ID';
            DataClassification = EndUserIdentifiableInformation;
            NotBlank = True;
            Trigger OnLookup()
            Var
                TaxComponent: Record "Tax Component";
                TaxTypeSetup: Record "Tax Type Setup";
            Begin
                if not TaxTypeSetup.Get() then
                    exit;
                TaxTypeSetup.TestField(Code);
                TaxComponent.SetRange("Tax Type", TaxTypeSetup.Code);
                IF Page.RunModal(Page::"Tax Components", TaxComponent) = Action::LookupOK Then Begin
                    "Component ID" := TaxComponent.Id;
                    "Component Name" := TaxComponent.Name;
                End;
            End;

            Trigger OnValidate()
            Var
                TaxComponent: Record "Tax Component";
                TaxTypeSetup: Record "Tax Type Setup";
            Begin
                IF xRec."Component ID" <> Rec."Component ID" Then Begin
                    if not TaxTypeSetup.Get() then
                        exit;
                    TaxTypeSetup.TestField(Code);
                    TaxComponent.Setrange("Tax Type", TaxTypeSetup.Code);
                    TaxComponent.SetRange(ID, "Component ID");
                    TaxComponent.FindFirst();
                    "Component Name" := TaxComponent.Name;
                End;
            End;
        }
        Field(2; "Component Name"; Text[30])
        {
            Caption = 'Component Name';
            Editable = false;
            DataClassification = EndUserIdentifiableInformation;
        }
    }
    keys
    {
        key(PK; "Component ID")
        {
            Clustered = true;
        }
    }
}