codeunit 139211 "Json Text Reader/Writer Test"
{
    Subtype = Test;

    trigger OnRun()
    begin
        // [FEATURE] [JSON] [UT]
    end;

    var
        Assert: Codeunit Assert;
        InvalidJsonValueTxt: Label 'Invalid Json Value for property %1';

    [Test]
    [Scope('OnPrem')]
    procedure TestWriter()
    var
        TempJSONBuffer: Record "JSON Buffer" temporary;
        JsonTextReaderWriter: Codeunit "Json Text Reader/Writer";
        LibraryLowerPermissions: Codeunit "Library - Lower Permissions";
        Json: Text;
    begin
        // [SCENARIO] Write Json and verify read Json
        LibraryLowerPermissions.SetO365Basic();

        // [GIVEN] https://en.wikipedia.org/wiki/JSON

        // [WHEN] Writing
        with JsonTextReaderWriter do begin
            WriteStartObject('');
            WriteStringProperty('firstName', 'John');
            WriteStringProperty('lastName', 'Smith');
            WriteBooleanProperty('isAlive', true);
            WriteNumberProperty('age', 27);
            WriteStartObject('address');
            WriteStringProperty('streetAddress', '21 2nd Street');
            WriteStringProperty('city', 'New York');
            WriteStringProperty('state', 'NY');
            WriteStringProperty('postalCode', '10021-3100');
            WriteEndObject();
            WriteStartArray('phoneNumbers');
            WriteStartObject('');
            WriteStringProperty('type', 'home');
            WriteStringProperty('number', '212 555-1234');
            WriteEndObject();
            WriteStartObject('');
            WriteStringProperty('type', 'office');
            WriteStringProperty('number', '646 555-4567');
            WriteEndObject();
            WriteStartObject('');
            WriteStringProperty('type', 'mobile');
            WriteStringProperty('number', '123 456-7890');
            WriteEndObject();
            WriteEndArray();
            WriteStartArray('children');
            WriteEndArray();
            WriteNullProperty('spouce');
            WriteEndObject();
            Json := GetJSonAsText();
        end;

        // [WHEN] Reading Json back into Json Buffer
        JsonTextReaderWriter.ReadJSonToJSonBuffer(Json, TempJSONBuffer);

        // [THEN] JsonBuffer content is identical to input values
        VerifyPropertyValue(TempJSONBuffer, 'firstName', 'John');
        VerifyPropertyValue(TempJSONBuffer, 'lastName', 'Smith');
        VerifyPropertyValue(TempJSONBuffer, 'isAlive', true);
        VerifyPropertyValue(TempJSONBuffer, 'age', 27);
        VerifyPropertyValue(TempJSONBuffer, 'streetAddress', '21 2nd Street');
        VerifyPropertyValue(TempJSONBuffer, 'city', 'New York');
        VerifyPropertyValue(TempJSONBuffer, 'state', 'NY');
        VerifyPropertyValue(TempJSONBuffer, 'postalCode', '10021-3100');
        VerifyPropertyValue(TempJSONBuffer, 'type', 'home');
        VerifyPropertyValue(TempJSONBuffer, 'number', '212 555-1234');
    end;

    local procedure VerifyPropertyValue(var TempJSONBuffer: Record "JSON Buffer" temporary; PropertyName: Text; PropertyValue: Variant)
    begin
        with TempJSONBuffer do begin
            SetRange("Token type", "Token type"::"Property Name");
            SetRange(Value, PropertyName);
            FindFirst();
            Reset();
            Next();
            case true of
                PropertyValue.IsText:
                    begin
                        Assert.AreEqual("Token type"::String, "Token type", StrSubstNo(InvalidJsonValueTxt, PropertyName));
                        Assert.AreEqual(PropertyValue, Value, StrSubstNo(InvalidJsonValueTxt, PropertyName));
                    end;
                PropertyValue.IsInteger, PropertyValue.IsDecimal:
                    begin
                        Assert.AreEqual("Token type"::Decimal, "Token type", StrSubstNo(InvalidJsonValueTxt, PropertyName));
                        Assert.AreEqual(Format(PropertyValue, 0, 9), Value, StrSubstNo(InvalidJsonValueTxt, PropertyName));
                    end;
                PropertyValue.IsBoolean:
                    begin
                        Assert.AreEqual("Token type"::Boolean, "Token type", StrSubstNo(InvalidJsonValueTxt, PropertyName));
                        Assert.AreEqual(Format(PropertyValue, 0, 9), Format(Value = 'Yes', 0, 9), StrSubstNo(InvalidJsonValueTxt, PropertyName));
                    end;
            end;
        end;
    end;
}

