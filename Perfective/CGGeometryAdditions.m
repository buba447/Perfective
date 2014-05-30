//
//  CGGeometryAdditions.m
//  localmind
//
//  Created by Nelson Gauthier on 11-10-25.
//  Copyright (c) 2011 Bitdingo. All rights reserved.
//

#import "CGGeometryAdditions.h"

//
// Core Graphics Geometry Additions
//

// CGRectIntegral returns a rectangle with the smallest integer values for its origin and size that contains the source rectangle.
// For a rect with .origin={5, 5.5}, .size=(10, 10), it will return .origin={5,5}, .size={10, 11};
// BBRectIntegral will return {5,5}, {10, 10}.
CGRect BBRectIntegral(CGRect rect) {
  rect.origin = CGPointMake(rintf(rect.origin.x), rintf(rect.origin.y));
  rect.size = CGSizeMake(ceilf(rect.size.width), ceil(rect.size.height));
  return rect;
}

//
// Centering

// Returns a rectangle of the given size, centered at a point

CGRect CGRectCenteredAtPoint(CGPoint center, CGSize size, BOOL integral) {
  CGRect result;
  result.origin.x = center.x - 0.5f * size.width;
  result.origin.y = center.y - 0.5f * size.height;
  result.size = size;
  
  if (integral) { result = BBRectIntegral(result); }
  return result;
}

// Returns the center point of a CGRect
CGPoint CGRectGetCenterPoint(CGRect rect) {
	return CGPointMake(CGRectGetMidX(rect), CGRectGetMidY(rect));
}

//
// Insetting

// Inset the rectangle on a single edge

CGRect CGRectInsetLeft(CGRect rect, CGFloat inset) {
  rect.origin.x += inset;
  rect.size.width -= inset;
  return rect;
}

CGRect CGRectInsetRight(CGRect rect, CGFloat inset) {
  rect.size.width -= inset;
  return rect;
}

CGRect CGRectInsetTop(CGRect rect, CGFloat inset) {
  rect.origin.y += inset;
  rect.size.height -= inset;
  return rect;
}

CGRect CGRectInsetBottom(CGRect rect, CGFloat inset) {
  rect.size.height -= inset;
  return rect;
}

// Inset the rectangle on two edges

CGRect CGRectInsetHorizontal(CGRect rect, CGFloat leftInset, CGFloat rightInset) {
  rect.origin.x += leftInset;
  rect.size.width -= (leftInset + rightInset);
  return rect;
}

CGRect CGRectInsetVertical(CGRect rect, CGFloat topInset, CGFloat bottomInset) {
  rect.origin.y += topInset;
  rect.size.height -= (topInset + bottomInset);
  return rect;
}

// Inset the rectangle on all edges

CGRect CGRectInsetAll(CGRect rect, CGFloat leftInset, CGFloat rightInset, CGFloat topInset, CGFloat bottomInset) {
  rect.origin.x += leftInset;
  rect.origin.y += topInset;
  rect.size.width -= (leftInset + rightInset);
  rect.size.height -= (topInset + bottomInset);
  return rect;
}

// Expand a size or rectangle by edge insets

CGFloat UIEdgeInsetsExpandWidth(CGFloat width, UIEdgeInsets insets) {
  return width + insets.left + insets.right;
}

CGFloat UIEdgeInsetsExpandHeight(CGFloat height, UIEdgeInsets insets) {
  return height + insets.top + insets.bottom;
}

CGSize UIEdgeInsetsExpandSize(CGSize size, UIEdgeInsets insets) {
  size.width += (insets.left + insets.right);
  size.height += (insets.top + insets.bottom);
  return size;
}

CGRect UIEdgeInsetsExpandRect(CGRect rect, UIEdgeInsets insets) {
  rect.origin.x -= insets.left;
  rect.origin.y -= insets.top;
  rect.size.width += (insets.left + insets.right);
  rect.size.height += (insets.top + insets.bottom);
  return rect;
}

//
// Framing

// Returns a rectangle of size framed in the center of the given rectangle

CGRect CGRectFramedCenteredInRect(CGRect rect, CGSize size, BOOL integral) {
  CGRect result;
  result.origin.x = rect.origin.x + rintf(0.5f * (rect.size.width - size.width));
  result.origin.y = rect.origin.y + rintf(0.5f * (rect.size.height - size.height));
  result.size = size;
  
  if (integral) { result = BBRectIntegral(result); }
  return result;
}

// Returns a rectangle of size framed in the given rectangle and inset

CGRect CGRectFramedLeftInRect(CGRect rect, CGSize size, CGFloat inset, BOOL integral) {
  CGRect result;
  result.origin.x = rect.origin.x + inset;
  result.origin.y = rect.origin.y + rintf(0.5f * (rect.size.height - size.height));
  result.size = size;
  
  if (integral) { result = BBRectIntegral(result); }
  return result;
}

CGRect CGRectFramedRightInRect(CGRect rect, CGSize size, CGFloat inset, BOOL integral) {
  CGRect result;
  result.origin.x = rect.origin.x + rect.size.width - size.width - inset;
  result.origin.y = rect.origin.y + rintf(0.5f * (rect.size.height - size.height));
  result.size = size;
  
  if (integral) { result = BBRectIntegral(result); }
  return result;
}

CGRect CGRectFramedTopInRect(CGRect rect, CGSize size, CGFloat inset, BOOL integral) {
  CGRect result;
  result.origin.x = rect.origin.x + rintf(0.5f * (rect.size.width - size.width));
  result.origin.y = rect.origin.y + inset;
  result.size = size;
  
  if (integral) { result = BBRectIntegral(result); }
  return result;
}

CGRect CGRectFramedBottomInRect(CGRect rect, CGSize size, CGFloat inset, BOOL integral) {
  CGRect result;
  result.origin.x = rect.origin.x + rintf(0.5f * (rect.size.width - size.width));
  result.origin.y = rect.origin.y + rect.size.height - size.height - inset;
  result.size = size;
  
  if (integral) { result = BBRectIntegral(result); }
  return result;
}

CGRect CGRectFramedTopLeftInRect(CGRect rect, CGSize size, CGFloat insetWidth, CGFloat insetHeight, BOOL integral) {
  CGRect result;
  result.origin.x = rect.origin.x + insetWidth;
  result.origin.y = rect.origin.y + insetHeight;
  result.size = size;
  
  if (integral) { result = BBRectIntegral(result); }
  return result;
}

CGRect CGRectFramedTopRightInRect(CGRect rect, CGSize size, CGFloat insetWidth, CGFloat insetHeight, BOOL integral) {
  CGRect result;
  result.origin.x = rect.origin.x + rect.size.width - size.width - insetWidth;
  result.origin.y = rect.origin.y + insetHeight;
  result.size = size;
  
  if (integral) { result = BBRectIntegral(result); }
  return result;
}

CGRect CGRectFramedBottomLeftInRect(CGRect rect, CGSize size, CGFloat insetWidth, CGFloat insetHeight, BOOL integral) {
  CGRect result;
  result.origin.x = rect.origin.x + insetWidth;
  result.origin.y = rect.origin.y + rect.size.height - size.height - insetHeight;
  result.size = size;
  
  if (integral) { result = BBRectIntegral(result); }
  return result;
}

CGRect CGRectFramedBottomRightInRect(CGRect rect, CGSize size, CGFloat insetWidth, CGFloat insetHeight, BOOL integral) {
  CGRect result;
  result.origin.x = rect.origin.x + rect.size.width - size.width - insetWidth;
  result.origin.y = rect.origin.y + rect.size.height - size.height - insetHeight;
  result.size = size;
  
  if (integral) { result = BBRectIntegral(result); }
  return result;
}

// Returns a rectangle of size attached to the given rectangle

CGRect CGRectAttachedLeftToRect(CGRect rect, CGSize size, CGFloat margin, BOOL integral) {
  CGRect result;
  result.origin.x = rect.origin.x - size.width - margin;
  result.origin.y = rect.origin.y + rintf(0.5f * (rect.size.height - size.height));
  result.size = size;
  
  if (integral) { result = BBRectIntegral(result); }
  return result;
}

CGRect CGRectAttachedRightToRect(CGRect rect, CGSize size, CGFloat margin, BOOL integral) {
  CGRect result;
  result.origin.x = rect.origin.x + rect.size.width + margin;
  result.origin.y = rect.origin.y + rintf(0.5f * (rect.size.height - size.height));
  result.size = size;
  
  if (integral) { result = BBRectIntegral(result); }
  return result;
}

CGRect CGRectAttachedTopToRect(CGRect rect, CGSize size, CGFloat margin, BOOL integral) {
  CGRect result;
  result.origin.x = rect.origin.x + rintf(0.5f * (rect.size.width - size.width));
  result.origin.y = rect.origin.y - size.height - margin;
  result.size = size;
  
  if (integral) { result = BBRectIntegral(result); }
  return result;
}

CGRect CGRectAttachedBottomToRect(CGRect rect, CGSize size, CGFloat margin, BOOL integral) {
  CGRect result;
  result.origin.x = rect.origin.x + rintf(0.5f * (rect.size.width - size.width));
  result.origin.y = rect.origin.y + rect.size.height + margin;
  result.size = size;
  
  if (integral) { result = BBRectIntegral(result); }
  return result;
}

CGRect CGRectAttachedBottomLeftToRect(CGRect rect, CGSize size, CGFloat marginWidth, CGFloat marginHeight, BOOL integral) {
  CGRect result;
  result.origin.x = rect.origin.x + marginWidth;
  result.origin.y = rect.origin.y + rect.size.height + marginHeight;
  result.size = size;
  
  if (integral) { result = BBRectIntegral(result); }
  return result;
}

CGRect CGRectAttachedBottomRightToRect(CGRect rect, CGSize size, CGFloat marginWidth, CGFloat marginHeight, BOOL integral) {
  CGRect result;
  result.origin.x = rect.origin.x + rect.size.width - size.width - marginWidth;
  result.origin.y = rect.origin.y + rect.size.height + marginHeight;
  result.size = size;
  
  if (integral) { result = BBRectIntegral(result); }
  return result;
}

// Divides a rect into sections and returns the section at specified index

CGRect CGRectDividedSection(CGRect rect, int sections, int index, CGRectEdge fromEdge) {
  if (sections == 0) {
    return CGRectZero;
  }
  CGRect r = rect;
  if (fromEdge == CGRectMaxXEdge || fromEdge == CGRectMinXEdge) {
    r.size.width = rect.size.width / sections;
    r.origin.x += r.size.width * index;
  } else {
    r.size.height = rect.size.height / sections;
    r.origin.y += r.size.height * index;
  }
  return r;
}


CGRect CGRectAddRect(CGRect rect, CGRect other) {
  return CGRectMake(rect.origin.x + other.origin.x, rect.origin.y + other.origin.y,
                    rect.size.width + other.size.width, rect.size.height + other.size.height);
}

CGRect CGRectAddPoint(CGRect rect, CGPoint point) {
  return CGRectMake(rect.origin.x + point.x, rect.origin.y + point.y,
                    rect.size.width, rect.size.height);
}

CGRect CGRectAddSize(CGRect rect, CGSize size) {
  return CGRectMake(rect.origin.x, rect.origin.y,
                    rect.size.width + size.width, rect.size.height + size.height);
}

CGRect CGRectBounded(CGRect rect) {
  CGRect returnRect = rect;
  returnRect.origin = CGPointZero;
  return returnRect;
}
