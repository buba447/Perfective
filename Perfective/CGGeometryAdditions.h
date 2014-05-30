//
//  CGGeometryAdditions.h
//  localmind
//
//  Created by Nelson Gauthier on 11-10-25.
//  Copyright (c) 2011 Bitdingo. All rights reserved.
//

#import <UIKit/UIKit.h>

//
// Core Graphics Geometry Additions
//

CGRect BBRectIntegral(CGRect rect);

// Centering

// Returns a rectangle of the given size, centered at a point
CGRect CGRectCenteredAtPoint(CGPoint center, CGSize size, BOOL integral);

// Returns the center point of a CGRect
CGPoint CGRectGetCenterPoint(CGRect rect);

// Insetting

// Inset the rectangle on a single edge
CGRect CGRectInsetLeft(CGRect rect, CGFloat inset);
CGRect CGRectInsetRight(CGRect rect, CGFloat inset);
CGRect CGRectInsetTop(CGRect rect, CGFloat inset);
CGRect CGRectInsetBottom(CGRect rect, CGFloat inset);

// Inset the rectangle on two edges
CGRect CGRectInsetHorizontal(CGRect rect, CGFloat leftInset, CGFloat rightInset);
CGRect CGRectInsetVertical(CGRect rect, CGFloat topInset, CGFloat bottomInset);

// Inset the rectangle on all edges
CGRect CGRectInsetAll(CGRect rect, CGFloat leftInset, CGFloat rightInset, CGFloat topInset, CGFloat bottomInset);

// Expand a size or rectangle by edge insets
CGFloat UIEdgeInsetsExpandWidth(CGFloat width, UIEdgeInsets insets);
CGFloat UIEdgeInsetsExpandHeight(CGFloat height, UIEdgeInsets insets);
CGSize UIEdgeInsetsExpandSize(CGSize size, UIEdgeInsets insets);
CGRect UIEdgeInsetsExpandRect(CGRect rect, UIEdgeInsets insets);

// Framing

// Returns a rectangle of size framed in the center of the given rectangle
CGRect CGRectFramedCenteredInRect(CGRect rect, CGSize size, BOOL integral);

// Returns a rectangle of size framed in the given rectangle and inset
CGRect CGRectFramedLeftInRect(CGRect rect, CGSize size, CGFloat inset, BOOL integral);
CGRect CGRectFramedRightInRect(CGRect rect, CGSize size, CGFloat inset, BOOL integral);
CGRect CGRectFramedTopInRect(CGRect rect, CGSize size, CGFloat inset, BOOL integral);
CGRect CGRectFramedBottomInRect(CGRect rect, CGSize size, CGFloat inset, BOOL integral);

CGRect CGRectFramedTopLeftInRect(CGRect rect, CGSize size, CGFloat insetWidth, CGFloat insetHeight, BOOL integral);
CGRect CGRectFramedTopRightInRect(CGRect rect, CGSize size, CGFloat insetWidth, CGFloat insetHeight, BOOL integral);
CGRect CGRectFramedBottomLeftInRect(CGRect rect, CGSize size, CGFloat insetWidth, CGFloat insetHeight, BOOL integral);
CGRect CGRectFramedBottomRightInRect(CGRect rect, CGSize size, CGFloat insetWidth, CGFloat insetHeight, BOOL integral);

// Divides a rect into sections and returns the section at specified index

CGRect CGRectDividedSection(CGRect rect, int sections, int index, CGRectEdge fromEdge);

// Returns a rectangle of size attached to the given rectangle
CGRect CGRectAttachedLeftToRect(CGRect rect, CGSize size, CGFloat margin, BOOL integral);
CGRect CGRectAttachedRightToRect(CGRect rect, CGSize size, CGFloat margin, BOOL integral);
CGRect CGRectAttachedTopToRect(CGRect rect, CGSize size, CGFloat margin, BOOL integral);
CGRect CGRectAttachedBottomToRect(CGRect rect, CGSize size, CGFloat margin, BOOL integral);

CGRect CGRectAttachedBottomLeftToRect(CGRect rect, CGSize size, CGFloat marginWidth, CGFloat marginHeight, BOOL integral);
CGRect CGRectAttachedBottomRightToRect(CGRect rect, CGSize size, CGFloat marginWidth, CGFloat marginHeight, BOOL integral);

// Combining
// Adds all values of the 2nd rect to the first rect
CGRect CGRectAddRect(CGRect rect, CGRect other);
CGRect CGRectAddPoint(CGRect rect, CGPoint point);
CGRect CGRectAddSize(CGRect rect, CGSize size);
CGRect CGRectBounded(CGRect rect);
