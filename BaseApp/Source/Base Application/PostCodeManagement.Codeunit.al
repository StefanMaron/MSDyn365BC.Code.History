codeunit 11401 "Post Code Management"
{

    trigger OnRun()
    begin
    end;

    var
        PostCodeLookupTable: Codeunit "Post Code Lookup - Table";

    [Scope('OnPrem')]
    procedure FindStreetNameFromAddress(var Address: Text[100]; var Address2: Text[50]; var PostCode: Code[20]; var City: Text[50]; CountryCode: Code[10]; var PhoneNo: Text[30]; var FaxNo: Text[30])
    var
        NewAddress: Text[100];
        NewStreetname: Text[50];
        NewHouseNo: Text[50];
        NewPostCode: Code[20];
        NewCity: Text[50];
        NewPhoneNo: Text[30];
        NewFaxNo: Text[30];
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeFindStreetNameFromAddress(IsHandled);
        if IsHandled then
            exit;

        NewAddress := DelChr(Address, '<');

        case true of
            NewAddress = '':
                exit;
            not ParseAddress(NewAddress, NewHouseNo, NewPostCode):
                exit;
        end;

        if not PostCodeLookupTable.FindStreetNameFromAddress(
             NewStreetname, NewHouseNo, NewPostCode, NewCity, NewPhoneNo, NewFaxNo)
        then
            exit;

        if StrLen(NewHouseNo) = 0 then begin
            Address :=
              DelChr(CopyStr(StrSubstNo('%1 %2', NewStreetname, NewAddress), 1, MaxStrLen(Address)), '<>');
            Address2 :=
              DelChr(CopyStr(StrSubstNo('%1 %2', NewStreetname, NewAddress), MaxStrLen(Address) + 1, MaxStrLen(Address2)), '<>');
        end else begin
            Address :=
              DelChr(CopyStr(StrSubstNo('%1 %2%3', NewStreetname, NewHouseNo, NewAddress), 1, MaxStrLen(Address)), '<>');
            Address2 :=
              DelChr(CopyStr(StrSubstNo('%1 %2%3', NewStreetname, NewHouseNo, NewAddress), MaxStrLen(Address) + 1,
                  MaxStrLen(Address2)), '<>');
        end;

        PostCode := NewPostCode;
        City := NewCity;

        case true of
            NewPhoneNo = '':
                ;
            PhoneNo = '':
                PhoneNo := StrSubstNo('%1-', NewPhoneNo);
            PhoneNo[StrLen(PhoneNo)] = '-':
                PhoneNo := StrSubstNo('%1-', NewPhoneNo);
        end;

        case true of
            NewFaxNo = '':
                ;
            FaxNo = '':
                FaxNo := StrSubstNo('%1-', NewFaxNo);
            FaxNo[StrLen(FaxNo)] = '-':
                FaxNo := StrSubstNo('%1-', NewFaxNo);
        end;

        OnAfterFindStreetNameFromAddress(Address, Address2, PostCode, City, CountryCode, PhoneNo, FaxNo);
    end;

    local procedure ParseAddress(var NewAddress: Text[100]; var NewHouseNo: Text[50]; var NewPostCode: Code[20]): Boolean
    var
        Done: Boolean;
    begin
        while (StrLen(NewAddress) > 0) and (not Done) do
            case StrLen(NewPostCode) of
                0 .. 3: // Find numbers
                    if NewAddress[1] in ['0' .. '9'] then begin
                        NewPostCode := NewPostCode + Format(NewAddress[1]);
                        NewAddress := DelChr(DelStr(NewAddress, 1, 1), '<');
                    end else
                        exit(false);
                4 .. 5: // Find letters
                    if UpperCase(Format(NewAddress[1])) in ['A' .. 'Z'] then begin
                        NewPostCode := NewPostCode + Format(NewAddress[1]);
                        NewAddress := DelChr(DelStr(NewAddress, 1, 1), '<');
                    end else
                        exit(false);
                else // Find house no.
                    if NewAddress[1] in ['0' .. '9'] then begin
                        NewHouseNo := NewHouseNo + Format(NewAddress[1]);
                        NewAddress := DelStr(NewAddress, 1, 1);
                    end else
                        exit(true);
            end;

        exit(true);
    end;

    [Scope('OnPrem')]
    procedure ParseAddressAdditionHouseNo(var StreetName: Text[100]; var HouseNo: Text[50]; var AdditionHouseNo: Text[50]; Address: Text[100])
    var
        HouseString: Text[50];
    begin
        StreetName := '';
        HouseNo := '';
        AdditionHouseNo := '';
        if Address = '' then
            exit;

        // Suppose that house string is a last word in the Address
        HouseString := GetHouseString(Address);

        if HouseString = '' then begin
            StreetName := Address;
            exit;
        end;

        // The last word is a House string with possible AdditionHouseNo information. All before last word is a StreetName.
        StreetName := CopyStr(Address, 1, StrLen(Address) - StrLen(HouseString) - 1);
        HouseNo := GetHouseNoFromHouseString(HouseString);
        AdditionHouseNo := HouseString;
    end;

    local procedure GetHouseString(Address: Text[100]): Text[50]
    var
        i: Integer;
    begin
        // If there's only one word then return empty HouseString
        if StrPos(Address, ' ') = 0 then
            exit('');

        // Find the last word: revert address string, cut first word, revert result
        RevertString(Address);

        // delete space symbols from the begining
        i := 1;
        while Address[i] = ' ' do
            i += 1;
        Address := CopyStr(Address, i);

        // cut the first word
        i := StrPos(Address, ' ');
        Address := CopyStr(Address, 1, i - 1);

        RevertString(Address);
        // If result word starts with digit then return it as HouseString
        if Address[1] in ['0' .. '9'] then
            exit(Address);

        exit('');
    end;

    local procedure GetHouseNoFromHouseString(var HouseString: Text[50]) HouseNo: Text[50]
    var
        Pos: Integer;
    begin
        Pos := 1;
        while HouseString[Pos] in ['0' .. '9'] do
            Pos += 1;
        HouseNo := CopyStr(HouseString, 1, Pos - 1);

        // remove HouseNo from the HouseString including special separating char if such exist
        if HouseString[Pos] in ['/', '\', '-'] then
            Pos += 1;
        HouseString := CopyStr(HouseString, Pos);
    end;

    local procedure RevertString(var String: Text[100])
    var
        StringCopy: Text[100];
        i: Integer;
        Length: Integer;
    begin
        StringCopy := String;
        Length := StrLen(String);
        for i := 1 to Length do
            String[i] := StringCopy[Length - i + 1];
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterFindStreetNameFromAddress(var Address: Text[100]; var Address2: Text[50]; var PostCode: Code[20]; var City: Text[50]; var CountryCode: Code[10]; var PhoneNo: Text[30]; var FaxNo: Text[30])
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeFindStreetNameFromAddress(var IsHandled: Boolean)
    begin
    end;
}

