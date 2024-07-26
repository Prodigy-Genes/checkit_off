import 'package:flutter/material.dart';

class FormContainer extends StatefulWidget {
  final TextEditingController? controller;
  final Key? fieldKey;
  final bool? isPasswordField;
  final String? hintText;
  final String? labelText;
  final String? helperText;
  final FormFieldSetter<String>? onSaved;
  final FormFieldValidator<String>? validator;
  final ValueChanged<String>? onFieldSubmitted;
  final TextInputType? inputType;

  const FormContainer({
    super.key,
    this.controller,
    this.fieldKey,
    this.isPasswordField,
    this.hintText,
    this.labelText,
    this.helperText,
    this.onSaved,
    this.validator,
    this.onFieldSubmitted,
    this.inputType,
  });

  @override
  State<FormContainer> createState() => _FormContainerState();
}

class _FormContainerState extends State<FormContainer> {
  bool _obscureText = true;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10),
      margin: const EdgeInsets.only(bottom: 15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(25),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: TextFormField(
        controller: widget.controller,
        keyboardType: widget.inputType,
        key: widget.fieldKey,
        obscureText: widget.isPasswordField ?? false ? _obscureText : false,
        onSaved: widget.onSaved,
        validator: widget.validator,
        onFieldSubmitted: widget.onFieldSubmitted,
        style: const TextStyle(color: Colors.blueAccent),
        decoration: InputDecoration(
          border: InputBorder.none,
          hintText: widget.hintText,
          hintStyle: const TextStyle(color: Colors.grey),
          labelText: widget.labelText,
          helperText: widget.helperText,
          filled: true,
          fillColor: Colors.transparent,
          prefixIcon: widget.isPasswordField == true
              ? const Icon(
                  Icons.lock_outlined,
                  color: Colors.blueAccent,
                  size: 16,
                )
              : widget.labelText == 'Email'
                  ? const Icon(
                      Icons.email,
                      color: Colors.blueAccent,
                      size: 16,
                    )
                  : widget.labelText == 'Username'
                      ? const Icon(Icons.person,color: Colors.blueAccent, size: 16,)
                      : null,
          suffixIcon: widget.isPasswordField == true
              ? GestureDetector(
                  onTap: () {
                    setState(() {
                      _obscureText = !_obscureText;
                    });
                  },
                  child: Icon(
                    _obscureText ? Icons.visibility_off : Icons.visibility,
                    color: _obscureText ? Colors.grey : Colors.blueAccent,
                  ),
                )
              : null,
        ),
      ),
    );
  }
}
